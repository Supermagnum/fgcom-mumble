# CMake generated Testfile for 
# Source directory: /home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests
# Build directory: /home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(ClientPluginModule_Basic_Tests "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/build/client_plugin_module_tests")
set_tests_properties(ClientPluginModule_Basic_Tests PROPERTIES  LABELS "basic;client_plugin_module" TIMEOUT "300" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;144;add_test;/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;0;")
add_test(ClientPluginModule_AddressSanitizer "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/build/client_plugin_module_tests_asan")
set_tests_properties(ClientPluginModule_AddressSanitizer PROPERTIES  LABELS "sanitizer;memory;client_plugin_module" TIMEOUT "600" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;145;add_test;/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;0;")
add_test(ClientPluginModule_ThreadSanitizer "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/build/client_plugin_module_tests_tsan")
set_tests_properties(ClientPluginModule_ThreadSanitizer PROPERTIES  LABELS "sanitizer;thread;client_plugin_module" TIMEOUT "600" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;146;add_test;/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;0;")
add_test(ClientPluginModule_Coverage "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/build/client_plugin_module_tests_coverage")
set_tests_properties(ClientPluginModule_Coverage PROPERTIES  LABELS "coverage;client_plugin_module" TIMEOUT "300" _BACKTRACE_TRIPLES "/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;147;add_test;/home/haaken/github-projects/fgcom-mumble/test/client_plugin_module_tests/CMakeLists.txt;0;")
