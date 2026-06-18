import hashlib

FLAVORS = ['afx', 'amirifx', 'askbid', 'celestial', 'goldenwolffx', 'kantara', 'octa', 'onsa', 'pipze', 'profx', 'sr', 'tenax', 'tenax3', 'tradoxy', 'vr19']
CONFIGS = ['Debug', 'Release', 'Profile']

pbxproj_path = "/Users/akash/Desktop/Soneji Infotech/xelthio/app/crmapp/ios/Runner.xcodeproj/project.pbxproj"

def make_uuid(seed):
    h = hashlib.md5(seed.encode()).hexdigest().upper()[:24]
    return h

# Build ID map
ids = {}
for flavor in FLAVORS:
    ids[flavor] = {}
    for cfg in CONFIGS:
        ids[flavor][cfg] = {
            'proj':   make_uuid(f"proj-{flavor}-{cfg}"),
            'runner': make_uuid(f"runner-{flavor}-{cfg}"),
            'tests':  make_uuid(f"tests-{flavor}-{cfg}"),
        }

with open(pbxproj_path, 'r') as f:
    content = f.read()

# Check if already patched
if 'Debug-afx' in content:
    print("Already patched!")
    exit(0)

# 1. Build XCBuildConfiguration blocks to inject
new_configs_block = "\n"
for flavor in FLAVORS:
    for cfg in CONFIGS:
        flutter_build_mode = cfg.lower()

        # project-level config
        proj_id = ids[flavor][cfg]['proj']
        lines = [
            f'\t\t{proj_id} /* {cfg}-{flavor} */ = {{',
            f'\t\t\tisa = XCBuildConfiguration;',
            f'\t\t\tbuildSettings = {{',
            f'\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;',
            f'\t\t\t\tCLANG_ANALYZER_NONNULL = YES;',
            f'\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++0x";',
            f'\t\t\t\tCLANG_CXX_LIBRARY = "libc++";',
            f'\t\t\t\tCLANG_ENABLE_MODULES = YES;',
            f'\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;',
            f'\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";',
            f'\t\t\t\tCOPY_PHASE_STRIP = NO;',
            f'\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;',
            f'\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = NO;',
            f'\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu99;',
            f'\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;',
            f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;',
            f'\t\t\t\tSDKROOT = iphoneos;',
            f'\t\t\t\tSUPPORTED_PLATFORMS = iphoneos;',
            f'\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";',
        ]
        if cfg == 'Debug':
            lines += [
                f'\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;',
                f'\t\t\t\tENABLE_TESTABILITY = YES;',
                f'\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;',
                f'\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;',
                '\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (',
                '\t\t\t\t\t"DEBUG=1",',
                '\t\t\t\t\t"$(inherited)",',
                '\t\t\t\t);',
                f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = YES;',
                f'\t\t\t\tONLY_ACTIVE_ARCH = YES;',
            ]
        elif cfg in ('Release', 'Profile'):
            lines += [
                f'\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";',
                f'\t\t\t\tENABLE_NS_ASSERTIONS = NO;',
                f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;',
                f'\t\t\t\tVALIDATE_PRODUCT = YES;',
            ]
        lines += [
            f'\t\t\t}};',
            f'\t\t\tname = "{cfg}-{flavor}";',
            f'\t\t}};',
        ]
        new_configs_block += '\n'.join(lines) + '\n'

        # runner target-level config
        runner_id = ids[flavor][cfg]['runner']
        base_xcconfig = '7AFA3C8E1D35360C0083082E /* Release.xcconfig */' if cfg in ('Release', 'Profile') else '9740EEB21CF90195004384FC /* Debug.xcconfig */'
        lines = [
            f'\t\t{runner_id} /* {cfg}-{flavor} */ = {{',
            f'\t\t\tisa = XCBuildConfiguration;',
            f'\t\t\tbaseConfigurationReference = {base_xcconfig};',
            f'\t\t\tbuildSettings = {{',
            f'\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;',
            f'\t\t\t\tCLANG_ENABLE_MODULES = YES;',
            f'\t\t\t\tCODE_SIGN_IDENTITY = "Apple Development";',
            f'\t\t\t\tCODE_SIGN_STYLE = Automatic;',
            f'\t\t\t\tCURRENT_PROJECT_VERSION = 1;',
            f'\t\t\t\tDEVELOPMENT_TEAM = W4MU85TDRR;',
            f'\t\t\t\tENABLE_BITCODE = NO;',
            f'\t\t\t\tFLUTTER_BUILD_MODE = {flutter_build_mode};',
            f'\t\t\t\tINFOPLIST_FILE = Runner/Info.plist;',
            f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;',
            '\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (',
            '\t\t\t\t\t"$(inherited)",',
            '\t\t\t\t\t"@executable_path/Frameworks",',
            '\t\t\t\t);',
            f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tenaxcode.app;',
            f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";',
            f'\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "";',
            f'\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";',
            f'\t\t\t\tSUPPORTS_MACCATALYST = NO;',
            f'\t\t\t\tSUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;',
            f'\t\t\t\tSUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;',
            f'\t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = "Runner/Runner-Bridging-Header.h";',
        ]
        if cfg == 'Debug':
            lines.append(f'\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";')
        lines += [
            f'\t\t\t\tSWIFT_VERSION = 5.0;',
            f'\t\t\t\tTARGETED_DEVICE_FAMILY = 1;',
            f'\t\t\t\tVERSIONING_SYSTEM = "apple-generic";',
            f'\t\t\t}};',
            f'\t\t\tname = "{cfg}-{flavor}";',
            f'\t\t}};',
        ]
        new_configs_block += '\n'.join(lines) + '\n'

        # tests target-level config
        tests_id = ids[flavor][cfg]['tests']
        lines = [
            f'\t\t{tests_id} /* {cfg}-{flavor} */ = {{',
            f'\t\t\tisa = XCBuildConfiguration;',
            f'\t\t\tbuildSettings = {{',
            f'\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";',
            f'\t\t\t\tCODE_SIGN_STYLE = Automatic;',
            f'\t\t\t\tCURRENT_PROJECT_VERSION = 1;',
            f'\t\t\t\tGENERATE_INFOPLIST_FILE = YES;',
            f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;',
            f'\t\t\t\tMARKETING_VERSION = 1.0;',
            f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.pipze.RunnerTests;',
            f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";',
        ]
        if cfg == 'Debug':
            lines += [
                f'\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;',
                f'\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";',
            ]
        lines += [
            f'\t\t\t\tSWIFT_VERSION = 5.0;',
            f'\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Runner.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Runner";',
            f'\t\t\t}};',
            f'\t\t\tname = "{cfg}-{flavor}";',
            f'\t\t}};',
        ]
        new_configs_block += '\n'.join(lines) + '\n'

# Inject before "/* End XCBuildConfiguration section */"
content = content.replace(
    '/* End XCBuildConfiguration section */',
    new_configs_block + '/* End XCBuildConfiguration section */'
)

# 2. Update XCConfigurationList entries

# RunnerTests config list (331C8087...)
tests_entries = ""
for flavor in FLAVORS:
    for cfg in CONFIGS:
        tests_entries += f'\t\t\t\t{ids[flavor][cfg]["tests"]} /* {cfg}-{flavor} */,\n'

old_tests = '\t\t\t\t331C808A294A63A400263BE5 /* Profile */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n\t\t97C146E91CF9000F007C117D'
new_tests = f'\t\t\t\t331C808A294A63A400263BE5 /* Profile */,\n{tests_entries}\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n\t\t97C146E91CF9000F007C117D'
if old_tests in content:
    content = content.replace(old_tests, new_tests)
    print("Patched RunnerTests config list")
else:
    print("WARNING: Could not find RunnerTests config list anchor!")

# Project config list (97C146E91CF9000F007C117D)
proj_entries = ""
for flavor in FLAVORS:
    for cfg in CONFIGS:
        proj_entries += f'\t\t\t\t{ids[flavor][cfg]["proj"]} /* {cfg}-{flavor} */,\n'

old_proj = '\t\t\t\t249021D3217E4FDB00AE95B9 /* Profile */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n\t\t97C147051CF9000F007C117D'
new_proj = f'\t\t\t\t249021D3217E4FDB00AE95B9 /* Profile */,\n{proj_entries}\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n\t\t97C147051CF9000F007C117D'
if old_proj in content:
    content = content.replace(old_proj, new_proj)
    print("Patched Project config list")
else:
    print("WARNING: Could not find Project config list anchor!")

# Runner target config list (97C147051CF9000F007C117D)
runner_entries = ""
for flavor in FLAVORS:
    for cfg in CONFIGS:
        runner_entries += f'\t\t\t\t{ids[flavor][cfg]["runner"]} /* {cfg}-{flavor} */,\n'

old_runner = '\t\t\t\t249021D4217E4FDB00AE95B9 /* Profile */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n/* End XCConfigurationList section */'
new_runner = f'\t\t\t\t249021D4217E4FDB00AE95B9 /* Profile */,\n{runner_entries}\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n/* End XCConfigurationList section */'
if old_runner in content:
    content = content.replace(old_runner, new_runner)
    print("Patched Runner target config list")
else:
    print("WARNING: Could not find Runner target config list anchor!")

with open(pbxproj_path, 'w') as f:
    f.write(content)

print("Done! project.pbxproj updated.")
