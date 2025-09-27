/* 
 * This file is part of the FGCom-mumble distribution (https://github.com/hbeni/fgcom-mumble).
 * Copyright (c) 2020 Benedikt Hallinger
 * 
 * This program is free software: you can redistribute it and/or modify  
 * it under the terms of the GNU General Public License as published by  
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */


// A modular radio model for the FGCom-mumble plugin
//
// The radio model is constructed from an abstract base class,
// which gets extended by concrete models for parts of the frequency spectrum.
// The model to be used for a given frequency can be retrived by the
// factory method fgcom_select_radiowave_model().

// include base implementation
#include "radio_model.h"

// include concrete implementations
#include "radio_model_vhf.cpp"
#include "radio_model_hf.cpp"
#include "radio_model_uhf.cpp"
#include "radio_model_string.cpp"
#include "radio_model_amateur.cpp"
#include "non_amateur_hf.cpp"
#include "advanced_modulation.cpp"


/*
* First some utitliy functions
*/

// Calculate and store current operable state of a radio
bool fgcom_radio_updateOperable(fgcom_radio &r){
    bool oldOperableValue = r.operable;
    if (r.frequency == "<del>") {
        r.operable = false; // deleted radios are never operable!
    } else {
        bool serviceable = r.serviceable;
        bool switchedOn  = r.power_btn;
        bool powered     = (r.volts >= 1.0)? true:false; // some aircraft report boolean here, so treat 1.0 as powered
        r.operable = (serviceable && switchedOn && powered);
    }
    
    return (r.operable != oldOperableValue);
}


/****************************************************/
/*          Implement base class                    */
/* Submodels are implemented separate and inherit   */
/****************************************************/

/*
* Radio model Factory: Selects the correct model based on the frequency given
* 
* @param  freq the frequency string
* @return FGCom_radiowaveModel instance that handles the frequency
*/
std::unique_ptr<FGCom_radiowaveModel> FGCom_radiowaveModel::selectModel(std::string freq) {
    fgcom_radiowave_freqConvRes freq_p = FGCom_radiowaveModel::splitFreqString(freq);
    if (freq_p.isNumeric) {
        // Select model based on frequency band.
        // Models, that say they are compatible to each other may implement frequency band overlapping.
        
        float frq_num = std::stof(freq_p.frequency);
        if (frq_num == 910.00) return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_VHF());  // echo test frequency (it is UHF, but needs to be treatened as VHF)
        
        // Check for aviation HF frequencies first
        FGCom_NonAmateurHF::initialize();
        if (FGCom_NonAmateurHF::isAviationFrequency(frq_num)) {
            return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_AviationHF(35000.0, "COMMERCIAL"));
        }
        
        // Check for maritime HF frequencies
        if (FGCom_NonAmateurHF::isMaritimeFrequency(frq_num)) {
            return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_MaritimeHF("COMMERCIAL", true));
        }
        
        // Check if this is an amateur radio frequency (1.8-54 MHz range)
        if (frq_num >= 1800.0 && frq_num <= 54000.0) {
            // Initialize amateur radio data to check if this is a valid amateur frequency
            FGCom_AmateurRadio::initialize();
            // For now, use region 1 (can be made configurable later)
            if (FGCom_AmateurRadio::isAmateurFrequency(frq_num, 1)) {
                return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_Amateur(1));
            }
        }
        
        if (frq_num <=  30.0)                    return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_HF());
        if (frq_num >  30.0 && frq_num <= 300.0) return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_VHF());
        if (frq_num > 300.0)                     return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_UHF());
        
        // every other case = frequency not handled specially yet: use VHF (line-of-sight) model
        return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_VHF());
    } else {
        // non-numeric: use string model
        return std::unique_ptr<FGCom_radiowaveModel>(new FGCom_radiowaveModel_String());
    }
}


/*
 * Extract numeric frequency from string and clean string from leading zeroes/spaces
 */
fgcom_radiowave_freqConvRes FGCom_radiowaveModel::splitFreqString(std::string frq) {
    setlocale(LC_NUMERIC,"C"); // decimal points always ".", not ","
    // construct default return value: use as-is
    struct fgcom_radiowave_freqConvRes res;
    res.frequency = frq;
    res.isNumeric = false;
    
    try {
        std::smatch sm;
        if (std::regex_match(frq, sm, std::regex("^[\\s0]*((?:RECORD_)?)([0-9.]+?)[\\s]*$") )) {
            // numeric frequency detected.
            // note: it is important for further detection that we keep the number of decimals unaltered!
            res.prefix    = sm[1];
            res.frequency = sm[2];
            res.isNumeric = true;
            return res;
        } else {
            // not numeric: use as-is
            return res;
        }
    } catch (const std::exception& e) {
        // parsing error: fall back to use-as-is
        return res;
    }
}




/********* default implementations, may be overloaded *************/

bool FGCom_radiowaveModel::isCompatible(FGCom_radiowaveModel *otherModel) {
    return this->getType() == otherModel->getType();
}


double FGCom_radiowaveModel::getDistToHorizon(float h) {
    // Formula is the simple one from https://en.wikipedia.org/wiki/Horizon#Objects_above_the_horizon
    // it is not perfectly accurate, but good enough for our purpose.
    return EARTH_RADIUS_CONST * sqrt(h);
}

double FGCom_radiowaveModel::heightAboveHorizon(double dist, float hA, float hB) {
    double horizA          = FGCom_radiowaveModel::getDistToHorizon(hA);
    double distB_behHoriz  = dist - horizA;
    if (distB_behHoriz < 0) {
        // negative: object is nearer than horizon = fully visible
        return hB;
        
    } else {
        // positive: the object is somewhere behind A's horizon and thus at least partly covered by earth
        double heightB_visible = pow(distB_behHoriz / EARTH_RADIUS_CONST, 2); // the result is the minimum visible altitude at that distance (A sees anything that is higher than this)
        double opticalHeight = hB - heightB_visible; // opticalHeight = real height - earth radius clipping
        
        return opticalHeight; // when negative: the object is hidden behind earth positive: the object appears that much above the horizont
    }
}

double FGCom_radiowaveModel::getSlantDistance(double surfacedist, double hah) {
    // simple pythargoras, where we search the hypotehnuse :)
    return sqrt( pow(surfacedist, 2) + pow(hah/1000, 2) );
}

double FGCom_radiowaveModel::degreeAboveHorizon(double surfacedist, double hah) {
    // simple pythargoras, where we search the angle alpha
    double distM = surfacedist * 1000; // in m because hah is also in m
    double hypo  = sqrt( pow(distM, 2) + pow(hah, 2) ); 
    
    if (hah == 0)  return 0; // in case of horizontal alignment
    if (hypo == 0) return (hah >=0)? 90: -90; // in case the tgt point lies directly above/below
    double sinA = hah / hypo;
    double angle = (sinA != 0)? asin(sinA) * (180.0 / M_PI) : 0;
    return angle;
}

double FGCom_radiowaveModel::getDirection(double lat1, double lon1, double lat2, double lon2) {
    // Get the target point as viewed from coordinate origin, so atan2 can get the quadrant right
    // We apply haversine here, so we get the real length based on lat/lon position on
    // earth (wgs84 cells are only regularly shaped near the equator: size depends on location)
    double dLat = FGCom_radiowaveModel::getSurfaceDistance(lat1, lon1, lat2, lon1); // y distance in km
    double dLon = FGCom_radiowaveModel::getSurfaceDistance(lat1, lon1, lat1, lon2); // x distance in km
    if (lat2 < lat1) dLat *= -1; // apply sign (down is negative vector)
    if (lon2 < lon1) dLon *= -1; // apply sign (left is negative vector)

    double brng = atan2(dLat, dLon) * (180.0 / M_PI);  // 0°=east, 90°=north, etc; lat=y, lon=x
    brng = 360 - brng; // count degrees clockwise
    brng += 90; // atan returns with east=0°, so we need to rotate right (atan counts counter-clockwise)
    
    // normalize values from -180/+180 to range 0/360
    if (brng < 360) brng += 360;
    if (brng > 360) brng -= 360;
    if (brng == 360) brng = 0;

    return brng;
}

double FGCom_radiowaveModel::getSurfaceDistance(double lat1, double lon1, 
                        double lat2, double lon2) {
    
    // The Haversine function does solve this for us.
    // Note that haversine assumes a perfect circular geoid, but earth is not perfect round.
    // for the distance we are talking here, that does not really matter tough.
    
    // This is the haversine function from Mahadev. Thank you very much!
    // taken from: https://www.geeksforgeeks.org/haversine-formula-to-find-distance-between-two-points-on-a-sphere/
    
    // distance between latitudes 
    // and longitudes 
    double dLat = (lat2 - lat1) * 
                    M_PI / 180.0; 
    double dLon = (lon2 - lon1) *  
                    M_PI / 180.0; 

    // convert to radians 
    lat1 = (lat1) * M_PI / 180.0; 
    lat2 = (lat2) * M_PI / 180.0; 

    // apply formulae 
    double a = pow(sin(dLat / 2), 2) +  
                pow(sin(dLon / 2), 2) *  
                cos(lat1) * cos(lat2); 
    double rad = EARTH_RADIUS_AVG; // average earth radius
    double c = 2 * asin(sqrt(a)); 
    return rad * c; 
}


//Generic channel width/spacing detection; may be used from the getFrqMatch() implementations
float FGCom_radiowaveModel::getChannelAlignment(float frq1_real, float frq2_real, float width_kHz, float core_kHz) {
    //std::cout << "DBG: FGCom_radiowaveModel::getChannelAlignment() called with:  frq1_real="<<frq1_real<<"; frq2_real="<<frq2_real<<"; width_kHZ="<<width_kHZ<<"; core_kHz=" << core_kHz << std::endl;
    
    // param checks: those need to be defined with concrete values
    if (width_kHz < 0) throw "FGCom_radiowaveModel::getFrqMatch() calling error: width_kHz not defined!";
    if (core_kHz  < 0) throw "FGCom_radiowaveModel::getFrqMatch() calling error: core_kHz not defined!";
    
    setlocale(LC_NUMERIC,"C"); // decimal points always ".", not ","
    float filter = 0.0; // no match in case of errors
    
    // TODO: currently a naive linear function, maybe adjust to curve:
    //       We make the difference absolute, so just looking at the half channel (it's mirrored on the left side of the center).
    //       If inside the core, we have 100% match. Outside, we decline linearly to zero.
    float diff_kHz     = std::fabs(frq1_real - frq2_real) * 1000; // difference in kHz
    float widthKhz_eff = (width_kHz) / 2;  // half band
    float corekHz_eff  = core_kHz  / 2;  // half band

    filter = 1 - diff_kHz + corekHz_eff;
    filter = 1 - (1/(widthKhz_eff-corekHz_eff)) * diff_kHz + corekHz_eff*1/(widthKhz_eff-corekHz_eff);  // 1-(1/(6-2.5))*x+2.5*1/(6-2.5)
    //std::cout << "DBG: FGCom_radiowaveModel::getChannelAlignment(): calc result="<<filter<<"; params: diff_kHz=" << diff_kHz << "; widthKhZ_eff="<< widthKhz_eff << "; corekHz_eff="<<corekHz_eff  <<std::endl;
    if (filter > 1.0) filter = 1.0;
    if (filter < 0.0) filter = 0.0;

    return filter;
}
