# 🎯 RTL Components Usage Guide

## 📋 **What We Created**

### **1. RTLComponents Class** (`lib/widgets/rtl_components.dart`)
A comprehensive library of RTL-aware UI components with default sizes and consistent styling.

### **2. Default Sizes**
```dart
static const double defaultHeight = 46.0;        // Default button/field height
static const double defaultBorderRadius = 12.0;  // Default border radius
static const double defaultPadding = 16.0;       // Default padding
static const double defaultMargin = 8.0;         // Default margin
```

## 🚀 **How to Use**

### **Step 1: Import the Components**
```dart
import '../widgets/rtl_components.dart';
```

### **Step 2: Replace Old Components**

#### **Before (Old Way):**
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16.h),
    minimumSize: Size(double.infinity, 46.h),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('Login'),
)
```

#### **After (New Way):**
```dart
RTLComponents.elevatedButton(
  text: 'Login',
  onPressed: () {},
  width: double.infinity,
)
```

## 🎨 **Available Components**

### **1. Buttons**

#### **Elevated Button**
```dart
RTLComponents.elevatedButton(
  text: 'Click Me',
  onPressed: () => print('Clicked!'),
  // Optional parameters:
  icon: Icon(Icons.star),
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  width: 200.w,
  height: 50, // Default is 46
  padding: EdgeInsets.all(20.w),
  borderRadius: BorderRadius.circular(20.r),
  isLoading: false,
)
```

#### **Outlined Button**
```dart
RTLComponents.outlinedButton(
  text: 'Outlined Button',
  onPressed: () => print('Clicked!'),
  // Optional parameters:
  borderColor: AppColors.success,
  textColor: AppColors.success,
  icon: Icon(Icons.check),
  width: 200.w,
  height: 50,
  isLoading: false,
)
```

#### **Text Button**
```dart
RTLComponents.textButton(
  text: 'Text Button',
  onPressed: () => print('Clicked!'),
  // Optional parameters:
  textColor: AppColors.primary,
  icon: Icon(Icons.link),
  width: 200.w,
  height: 40,
  isLoading: false,
)
```

### **2. Text Fields**
```dart
RTLComponents.textField(
  controller: emailController,
  labelText: 'Email',
  hintText: 'Enter your email',
  // Optional parameters:
  keyboardType: TextInputType.emailAddress,
  obscureText: false,
  prefixIcon: Icon(Icons.email),
  suffixIcon: Icon(Icons.visibility),
  height: 50, // Default is 46
  borderColor: AppColors.success,
  focusedBorderColor: AppColors.primary,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
  onChanged: (value) => print('Changed: $value'),
)
```

### **3. Cards & Containers**
```dart
// Card
RTLComponents.card(
  child: Text('Card Content'),
  // Optional parameters:
  color: AppColors.cardBackGround,
  elevation: 4,
  borderRadius: BorderRadius.circular(20.r),
  padding: EdgeInsets.all(20.w),
  margin: EdgeInsets.all(10.w),
)

// Container
RTLComponents.container(
  child: Text('Container Content'),
  // Optional parameters:
  color: AppColors.secondary,
  borderRadius: BorderRadius.circular(8.r),
  border: Border.all(color: AppColors.border),
  width: 200.w,
  height: 100.h,
  alignment: Alignment.center,
)
```

### **4. Layout Components**
```dart
// Row with automatic spacing
RTLComponents.row(
  children: [
    Icon(Icons.star),
    Icon(Icons.favorite),
    Icon(Icons.bookmark),
  ],
  // Optional parameters:
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  spacing: 16, // Default is 16
)

// Column with automatic spacing
RTLComponents.column(
  children: [
    Text('Item 1'),
    Text('Item 2'),
    Text('Item 3'),
  ],
  // Optional parameters:
  mainAxisAlignment: MainAxisAlignment.start,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 12, // Default is 16
)
```

### **5. Icon Buttons**
```dart
RTLComponents.iconButton(
  icon: Icons.favorite,
  onPressed: () => print('Liked!'),
  // Optional parameters:
  size: 24.sp,
  backgroundColor: AppColors.error,
  foregroundColor: Colors.white,
  width: 50.w,
  height: 50, // Default is 46
  padding: EdgeInsets.all(8.w),
  borderRadius: BorderRadius.circular(25.r),
)
```

### **6. List Tiles**
```dart
RTLComponents.listTile(
  title: 'Settings',
  subtitle: 'Manage your preferences',
  // Optional parameters:
  leading: Icon(Icons.settings),
  trailing: Icon(Icons.arrow_forward),
  onTap: () => print('Settings tapped'),
  contentPadding: EdgeInsets.all(16.w),
)
```

## 🔄 **Migration Steps**

### **Step 1: Update Imports**
```dart
// Add this import to your screen files
import '../widgets/rtl_components.dart';
```

### **Step 2: Replace Buttons**
```dart
// OLD
ElevatedButton(
  onPressed: () {},
  child: Text('Login'),
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16.h),
    minimumSize: Size(double.infinity, 46.h),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)

// NEW
RTLComponents.elevatedButton(
  text: 'Login',
  onPressed: () {},
  width: double.infinity,
)
```

### **Step 3: Replace Text Fields**
```dart
// OLD
RTLHelper.rtlTextField(
  controller: controller,
  labelText: 'Email',
  // ... other parameters
)

// NEW
RTLComponents.textField(
  controller: controller,
  labelText: 'Email',
  // ... other parameters
)
```

### **Step 4: Replace Layout Components**
```dart
// OLD
Row(
  children: [
    widget1,
    SizedBox(width: 16.w),
    widget2,
    SizedBox(width: 16.w),
    widget3,
  ],
)

// NEW
RTLComponents.row(
  children: [widget1, widget2, widget3],
  spacing: 16,
)
```

## 🎯 **Benefits**

### **1. Consistency**
- All components use the same default sizes
- Consistent spacing and styling
- Unified design language

### **2. RTL Support**
- Automatic RTL layout handling
- Icon flipping for RTL languages
- Proper text direction

### **3. Maintainability**
- Single place to update styles
- Easy to modify default values
- Reduced code duplication

### **4. Developer Experience**
- Shorter, cleaner code
- Less repetitive styling
- Built-in loading states

## 📱 **Example Usage in Screens**

### **Login Screen**
```dart
Column(
  children: [
    RTLComponents.textField(
      controller: emailController,
      labelText: 'Email',
      prefixIcon: Icon(Icons.email),
    ),
    SizedBox(height: 16.h),
    RTLComponents.textField(
      controller: passwordController,
      labelText: 'Password',
      obscureText: true,
      prefixIcon: Icon(Icons.lock),
    ),
    SizedBox(height: 24.h),
    RTLComponents.elevatedButton(
      text: 'Login',
      onPressed: _handleLogin,
      width: double.infinity,
    ),
  ],
)
```

### **Settings Screen**
```dart
RTLComponents.column(
  children: [
    RTLComponents.listTile(
      title: 'Profile',
      subtitle: 'Edit your profile',
      leading: Icon(Icons.person),
      onTap: () => Get.toNamed('/profile'),
    ),
    RTLComponents.listTile(
      title: 'Notifications',
      subtitle: 'Manage notifications',
      leading: Icon(Icons.notifications),
      onTap: () => Get.toNamed('/notifications'),
    ),
  ],
  spacing: 8,
)
```

## 🚨 **Important Notes**

### **1. Default Values**
- Height: 46.h (matches your design)
- Border radius: 12.r
- Padding: 16.w
- Margin: 8.w

### **2. RTL Behavior**
- Components automatically handle RTL layouts
- Icons flip appropriately
- Text direction is managed automatically

### **3. Customization**
- All default values can be overridden
- Components accept standard Flutter parameters
- Maintains flexibility while providing consistency

## 🔧 **Customization**

### **Global Default Changes**
To change defaults for the entire app, modify the constants in `RTLComponents`:

```dart
class RTLComponents {
  // Change these values to update app-wide defaults
  static const double defaultHeight = 50.0;        // Was 46.0
  static const double defaultBorderRadius = 16.0;  // Was 12.0
  static const double defaultPadding = 20.0;       // Was 16.0
  static const double defaultMargin = 12.0;        // Was 8.0
}
```

### **Component-Level Customization**
```dart
RTLComponents.elevatedButton(
  text: 'Custom Button',
  onPressed: () {},
  height: 60,           // Override default height
  borderRadius: BorderRadius.circular(25.r), // Override default radius
  padding: EdgeInsets.all(20.w),            // Override default padding
)
```

This approach gives you the best of both worlds: consistent defaults and full customization when needed!
