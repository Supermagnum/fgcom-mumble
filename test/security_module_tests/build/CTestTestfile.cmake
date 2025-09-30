# CMake generated Testfile for 
# Source directory: /home/haaken/github-projects/fgcom-mumble/test/security_module_tests
# Build directory: /home/haaken/github-projects/fgcom-mumble/test/security_module_tests/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(SecurityModule_Basic_Tests "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/build/security_module_tests")
set_tests_properties(SecurityModule_Basic_Tests PROPERTIES  LABELS "basic;security_module" TIMEOUT "300" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;128;add_test;/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;0;")
add_test(SecurityModule_AddressSanitizer "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/build/security_module_tests_asan")
set_tests_properties(SecurityModule_AddressSanitizer PROPERTIES  LABELS "sanitizer;memory;security_module" TIMEOUT "600" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;129;add_test;/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;0;")
add_test(SecurityModule_ThreadSanitizer "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/build/security_module_tests_tsan")
set_tests_properties(SecurityModule_ThreadSanitizer PROPERTIES  LABELS "sanitizer;thread;security_module" TIMEOUT "600" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;130;add_test;/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;0;")
add_test(SecurityModule_Coverage "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/build/security_module_tests_coverage")
set_tests_properties(SecurityModule_Coverage PROPERTIES  LABELS "coverage;security_module" TIMEOUT "300" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;131;add_test;/home/haaken/github-projects/fgcom-mumble/test/security_module_tests/CMakeLists.txt;0;")
