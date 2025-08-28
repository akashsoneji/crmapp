#!/usr/bin/env python3
"""
Brand Switcher Script for Flutter App
=====================================

This script helps you easily switch between different brands (Pipze, Octa, Fleza)
by updating all necessary configuration files at once.

Usage:
    python switch_brand.py pipze    # Switch to Pipze (Purple)
    python switch_brand.py octa     # Switch to Octa (Orange)  
    python switch_brand.py fleza    # Switch to Fleza (Green)

What it updates:
1. lib/constants/app_config.dart - Brand colors and names
2. pubspec.yaml - Package name
3. android/app/src/main/AndroidManifest.xml - App label
4. flutter_launcher_icons.yaml - Launcher icon path
5. Creates brand-specific asset folders
"""

import os
import sys
import re
from pathlib import Path

# Brand configurations
BRANDS = {
    'pipze': {
        'name': 'pipze',
        'displayName': 'Pipze',
        'primaryColor': 'Color(0xFF5A2DD8)',      # Purple
        'secondaryColor': 'Color(0xFFF8F3FF)',    # Light Purple
        'accentColor': 'Color(0xFF9C27B0)',       # Dark Purple
        'launcherIcon': 'assets/image/splash_logo.png',
        'splashLogo': 'assets/image/splash_logo.png',
        'webBackgroundColor': '#5A2DD8',
        'webThemeColor': '#5A2DD8',
    },
    'octa': {
        'name': 'octa',
        'displayName': 'Octa',
        'primaryColor': 'Color(0xFFFF6B35)',      # Orange
        'secondaryColor': 'Color(0xFFFFF3E0)',    # Light Orange
        'accentColor': 'Color(0xFFE65100)',       # Dark Orange
        'launcherIcon': 'assets/image/octa_launcher.png',
        'splashLogo': 'assets/image/octa_splash.png',
        'webBackgroundColor': '#FF6B35',
        'webThemeColor': '#FF6B35',
    },
    'fleza': {
        'name': 'fleza',
        'displayName': 'Fleza',
        'primaryColor': 'Color(0xFF4CAF50)',      # Green
        'secondaryColor': 'Color(0xFFE8F5E8)',    # Light Green
        'accentColor': 'Color(0xFF2E7D32)',       # Dark Green
        'launcherIcon': 'assets/image/fleza_launcher.png',
        'splashLogo': 'assets/image/fleza_splash.png',
        'webBackgroundColor': '#4CAF50',
        'webThemeColor': '#4CAF50',
    }
}

def update_app_config(brand):
    """Update the app_config.dart file"""
    config_file = 'lib/constants/app_config.dart'
    
    with open(config_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update the currentBrand constant
    content = re.sub(
        r'const AppBrand currentBrand = AppBrand\.\w+;',
        f'const AppBrand currentBrand = AppBrand.{brand};',
        content
    )
    
    with open(config_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Updated {config_file}")

def update_pubspec(brand):
    """Update the pubspec.yaml file"""
    pubspec_file = 'pubspec.yaml'
    
    with open(pubspec_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update package name
    content = re.sub(
        r'^name: \w+',
        f'name: {brand}',
        content,
        flags=re.MULTILINE
    )
    
    with open(pubspec_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Updated {pubspec_file}")

def update_android_manifest(brand):
    """Update the Android manifest file"""
    manifest_file = 'android/app/src/main/AndroidManifest.xml'
    
    with open(manifest_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update app label
    content = re.sub(
        r'android:label="[^"]*"',
        f'android:label="{brand}"',
        content
    )
    
    with open(manifest_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Updated {manifest_file}")

def update_launcher_icons(brand):
    """Update the flutter_launcher_icons.yaml file"""
    icons_file = 'flutter_launcher_icons.yaml'
    
    with open(icons_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    brand_config = BRANDS[brand]
    
    # Update image paths
    content = re.sub(
        r'image_path: "[^"]*"',
        f'image_path: "{brand_config["launcherIcon"]}"',
        content
    )
    
    # Update web colors
    content = re.sub(
        r'background_color: "[^"]*"',
        f'background_color: "{brand_config["webBackgroundColor"]}"',
        content
    )
    content = re.sub(
        r'theme_color: "[^"]*"',
        f'theme_color: "{brand_config["webThemeColor"]}"',
        content
    )
    
    with open(icons_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Updated {icons_file}")

def create_asset_folders(brand):
    """Create brand-specific asset folders if they don't exist"""
    brand_config = BRANDS[brand]
    
    # Create assets/image folder if it doesn't exist
    assets_dir = Path('assets/image')
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    # Check if launcher icon exists, if not create a placeholder
    launcher_icon = Path(brand_config['launcherIcon'])
    if not launcher_icon.exists():
        print(f"⚠️  Warning: {launcher_icon} does not exist")
        print(f"   Please add your {brand} launcher icon to: {launcher_icon}")
    
    print(f"✅ Asset folders checked")

def main():
    if len(sys.argv) != 2:
        print("Usage: python switch_brand.py <brand>")
        print("Available brands:", ", ".join(BRANDS.keys()))
        sys.exit(1)
    
    brand = sys.argv[1].lower()
    
    if brand not in BRANDS:
        print(f"❌ Error: Unknown brand '{brand}'")
        print("Available brands:", ", ".join(BRANDS.keys()))
        sys.exit(1)
    
    print(f"🔄 Switching to {BRANDS[brand]['displayName']} brand...")
    print(f"   Primary Color: {BRANDS[brand]['primaryColor']}")
    print(f"   Launcher Icon: {BRANDS[brand]['launcherIcon']}")
    print()
    
    try:
        update_app_config(brand)
        update_pubspec(brand)
        update_android_manifest(brand)
        update_launcher_icons(brand)
        create_asset_folders(brand)
        
        print()
        print(f"🎉 Successfully switched to {BRANDS[brand]['displayName']}!")
        print()
        print("Next steps:")
        print("1. Add your brand launcher icon to: assets/image/")
        print("2. Run: flutter clean")
        print("3. Run: flutter pub get")
        print("4. Run: flutter pub run flutter_launcher_icons:main")
        print("5. Build your app!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
