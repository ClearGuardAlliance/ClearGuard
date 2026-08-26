#!/usr/bin/env python3
import shutil
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NATIVE_ANDROID = ROOT / "native_android"
ANDROID_APP = ROOT / "android" / "app"
PACKAGE_PATH = "com/clearguardalliance/clearguard"

ANDROID_NS = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID_NS)


def qn(tag: str) -> str:
    return f"{{{ANDROID_NS}}}{tag}"


def copy_kotlin_sources() -> None:
    destination = ANDROID_APP / "src" / "main" / "kotlin" / PACKAGE_PATH
    destination.mkdir(parents=True, exist_ok=True)
    for source in (NATIVE_ANDROID / "kotlin").glob("*.kt"):
        shutil.copy(source, destination / source.name)
        print(f"copied {source.name} -> {destination / source.name}")


def copy_resources() -> None:
    xml_destination = ANDROID_APP / "src" / "main" / "res" / "xml"
    xml_destination.mkdir(parents=True, exist_ok=True)
    for source in (NATIVE_ANDROID / "res" / "xml").glob("*.xml"):
        shutil.copy(source, xml_destination / source.name)
        print(f"copied {source.name} -> {xml_destination / source.name}")

    values_destination = ANDROID_APP / "src" / "main" / "res" / "values"
    values_destination.mkdir(parents=True, exist_ok=True)
    generated_strings = values_destination / "strings.xml"
    source_strings = NATIVE_ANDROID / "res" / "values" / "strings.xml"
    if generated_strings.exists():
        print("strings.xml already exists, merging string entries")
        merge_strings(generated_strings, source_strings)
    else:
        shutil.copy(source_strings, generated_strings)
        print(f"copied strings.xml -> {generated_strings}")


def merge_strings(generated: Path, source: Path) -> None:
    generated_tree = ET.parse(generated)
    generated_root = generated_tree.getroot()
    existing_names = {el.get("name") for el in generated_root.findall("string")}

    source_root = ET.parse(source).getroot()
    changed = False
    for string_element in source_root.findall("string"):
        if string_element.get("name") not in existing_names:
            generated_root.append(string_element)
            changed = True

    if changed:
        generated_tree.write(generated, encoding="utf-8", xml_declaration=True)


def add_permissions(root: ET.Element, application: ET.Element) -> None:
    permissions = [
        "android.permission.INTERNET",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_SPECIAL_USE",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.BIND_ACCESSIBILITY_SERVICE",
    ]

    existing = {el.get(qn("name")) for el in root.findall("uses-permission")}
    app_index = list(root).index(application)
    for permission in permissions:
        if permission in existing:
            continue
        element = ET.Element("uses-permission")
        element.set(qn("name"), permission)
        root.insert(app_index, element)
        app_index += 1
        print(f"added permission {permission}")


def build_vpn_service() -> ET.Element:
    service = ET.Element("service")
    service.set(qn("name"), ".BlockerVpnService")
    service.set(qn("exported"), "false")
    service.set(qn("foregroundServiceType"), "specialUse")
    service.set(qn("permission"), "android.permission.BIND_VPN_SERVICE")

    prop = ET.SubElement(service, "property")
    prop.set(qn("name"), "android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE")
    prop.set(qn("value"), "Parental-control DNS filtering VPN")

    intent_filter = ET.SubElement(service, "intent-filter")
    action = ET.SubElement(intent_filter, "action")
    action.set(qn("name"), "android.net.VpnService")

    return service


def build_accessibility_service() -> ET.Element:
    service = ET.Element("service")
    service.set(qn("name"), ".ScreenContentMonitorService")
    service.set(qn("exported"), "false")
    service.set(qn("permission"), "android.permission.BIND_ACCESSIBILITY_SERVICE")

    intent_filter = ET.SubElement(service, "intent-filter")
    action = ET.SubElement(intent_filter, "action")
    action.set(qn("name"), "android.accessibilityservice.AccessibilityService")

    meta_data = ET.SubElement(service, "meta-data")
    meta_data.set(qn("name"), "android.accessibilityservice")
    meta_data.set(qn("resource"), "@xml/accessibility_service_config")

    return service


def build_overlay_activity() -> ET.Element:
    activity = ET.Element("activity")
    activity.set(qn("name"), ".BlockOverlayActivity")
    activity.set(qn("exported"), "false")
    activity.set(qn("excludeFromRecents"), "true")
    activity.set(qn("launchMode"), "singleTask")
    activity.set(qn("theme"), "@android:style/Theme.Black.NoTitleBar.Fullscreen")
    return activity


def build_device_admin_receiver() -> ET.Element:
    receiver = ET.Element("receiver")
    receiver.set(qn("name"), ".ClearGuardDeviceAdminReceiver")
    receiver.set(qn("exported"), "false")
    receiver.set(qn("permission"), "android.permission.BIND_DEVICE_ADMIN")

    meta_data = ET.SubElement(receiver, "meta-data")
    meta_data.set(qn("name"), "android.app.device_admin")
    meta_data.set(qn("resource"), "@xml/device_admin_policies")

    intent_filter = ET.SubElement(receiver, "intent-filter")
    action = ET.SubElement(intent_filter, "action")
    action.set(qn("name"), "android.app.action.DEVICE_ADMIN_ENABLED")

    return receiver


def add_application_entries(application: ET.Element) -> None:
    existing_names = {
        child.get(qn("name")) for child in application if child.get(qn("name"))
    }

    entries = [
        (".BlockerVpnService", build_vpn_service),
        (".ScreenContentMonitorService", build_accessibility_service),
        (".BlockOverlayActivity", build_overlay_activity),
        (".ClearGuardDeviceAdminReceiver", build_device_admin_receiver),
    ]

    for name, build in entries:
        if name in existing_names:
            print(f"{name} already present, skipping")
            continue
        application.append(build())
        print(f"added {name}")


def merge_manifest() -> None:
    manifest_path = ANDROID_APP / "src" / "main" / "AndroidManifest.xml"
    if not manifest_path.exists():
        sys.exit(f"AndroidManifest.xml not found at {manifest_path}. Run flutter create first.")

    tree = ET.parse(manifest_path)
    root = tree.getroot()
    application = root.find("application")
    if application is None:
        sys.exit("<application> element not found in AndroidManifest.xml")

    add_permissions(root, application)
    add_application_entries(application)

    if hasattr(ET, "indent"):
        ET.indent(tree, space="    ")

    tree.write(manifest_path, encoding="utf-8", xml_declaration=True)
    print(f"merged manifest at {manifest_path}")


def remove_stock_widget_test() -> None:
    stock_test = ROOT / "test" / "widget_test.dart"
    if not stock_test.exists():
        return
    if "MyApp" in stock_test.read_text():
        stock_test.unlink()
        print(f"removed stock template test at {stock_test}")


def main() -> None:
    if not (ROOT / "android").exists():
        sys.exit("android/ not found. Run `flutter create --platforms=android "
                  "--org com.clearguardalliance -a kotlin .` first.")

    copy_kotlin_sources()
    copy_resources()
    merge_manifest()
    remove_stock_widget_test()
    print("native Android integration applied")


if __name__ == "__main__":
    main()
