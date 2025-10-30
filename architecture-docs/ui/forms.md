# Form Handling Documentation

**Part of:** [ARCHITECTURE.md](../ARCHITECTURE.md) - Complete system architecture guide

This document provides comprehensive patterns and examples for form handling in the HackTracker Flutter application, including input validation, form state management, error display, and accessibility.

---

## Table of Contents

1. [Input Validation](#input-validation)
2. [Form State Management](#form-state-management)
3. [Error Display](#error-display)
4. [Autofill Prevention](#autofill-prevention)
5. [Accessibility](#accessibility)
6. [Form Patterns](#form-patterns)
7. [Testing Forms](#testing-forms)

---

## Input Validation

### Validation Functions

HackTracker uses consistent validation functions across all forms:

```dart
// app/lib/utils/form_validators.dart
class FormValidators {
  // Team name validation
  static String? validateTeamName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Team name is required';
    }
    
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Team name must be at least 3 characters';
    }
    
    if (trimmed.length > 50) {
      return 'Team name must be less than 50 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(trimmed)) {
      return 'Team name can only contain letters, numbers, and spaces';
    }
    
    return null;
  }
  
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    
    return null;
  }
  
  // Password confirmation validation
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Player name validation
  static String? validatePlayerName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final trimmed = value.trim();
    if (trimmed.length < 1) {
      return '$fieldName must be at least 1 character';
    }
    
    if (trimmed.length > 30) {
      return '$fieldName must be less than 30 characters';
    }
    
    // Allow letters, hyphens, apostrophes, periods, and accented characters
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-\'\.]+$').hasMatch(trimmed)) {
      return '$fieldName can only contain letters, spaces, hyphens, apostrophes, and periods';
    }
    
    return null;
  }
  
  // Player number validation
  static String? validatePlayerNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Player number is optional
    }
    
    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Player number must be a valid number';
    }
    
    if (number < 0 || number > 99) {
      return 'Player number must be between 0 and 99';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone number is optional
    }
    
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
}
```

### Validation Usage in Forms

```dart
// Using validators in form fields
class CreateTeamForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<CreateTeamForm> createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends ConsumerState<CreateTeamForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextFormField(
            controller: _nameController,
            labelText: 'Team Name',
            hintText: 'Enter team name',
            validator: FormValidators.validateTeamName,
          ),
          SizedBox(height: 16),
          AppTextFormField(
            controller: _descController,
            labelText: 'Description',
            hintText: 'Enter team description (optional)',
            maxLines: 3,
            validator: (value) {
              if (value != null && value.length > 500) {
                return 'Description must be less than 500 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
```

### Real-time Validation

```dart
// Real-time validation with onChanged
class RealTimeValidationForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<RealTimeValidationForm> createState() => _RealTimeValidationFormState();
}

class _RealTimeValidationFormState extends ConsumerState<RealTimeValidationForm> {
  final _emailController = TextEditingController();
  String? _emailError;
  
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: _emailController,
      labelText: 'Email',
      hintText: 'Enter your email',
      onChanged: (value) {
        setState(() {
          _emailError = FormValidators.validateEmail(value);
        });
      },
      validator: (value) => _emailError,
    );
  }
}
```

---

## Form State Management

### Form Key Pattern

```dart
class FormStateExample extends ConsumerStatefulWidget {
  @override
  ConsumerState<FormStateExample> createState() => _FormStateExampleState();
}

class _FormStateExampleState extends ConsumerState<FormStateExample> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed with submission
      _submitData();
    } else {
      // Form is invalid, show error message
      Messenger.showError(context, 'Please fix the errors above');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextFormField(
            controller: _nameController,
            labelText: 'Name',
            validator: FormValidators.validatePlayerName,
          ),
          AppTextFormField(
            controller: _emailController,
            labelText: 'Email',
            validator: FormValidators.validateEmail,
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

### Form Data Models

```dart
// Form data models for type safety
class TeamFormData {
  final String name;
  final String? description;
  
  TeamFormData({
    required this.name,
    this.description,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class PlayerFormData {
  final String firstName;
  final String? lastName;
  final int? playerNumber;
  final String status;
  
  PlayerFormData({
    required this.firstName,
    this.lastName,
    this.playerNumber,
    this.status = 'active',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'playerNumber': playerNumber,
      'status': status,
    };
  }
}
```

### Form State with Riverpod

```dart
// Form state management with Riverpod
final teamFormProvider = StateNotifierProvider<TeamFormNotifier, TeamFormState>(
  (ref) => TeamFormNotifier(),
);

class TeamFormState {
  final String name;
  final String? description;
  final bool isValid;
  final Map<String, String> errors;
  
  TeamFormState({
    this.name = '',
    this.description,
    this.isValid = false,
    this.errors = const {},
  });
  
  TeamFormState copyWith({
    String? name,
    String? description,
    bool? isValid,
    Map<String, String>? errors,
  }) {
    return TeamFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
    );
  }
}

class TeamFormNotifier extends StateNotifier<TeamFormState> {
  TeamFormNotifier() : super(TeamFormState());
  
  void updateName(String name) {
    final errors = Map<String, String>.from(state.errors);
    final nameError = FormValidators.validateTeamName(name);
    
    if (nameError != null) {
      errors['name'] = nameError;
    } else {
      errors.remove('name');
    }
    
    state = state.copyWith(
      name: name,
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  void updateDescription(String? description) {
    final errors = Map<String, String>.from(state.errors);
    
    if (description != null && description.length > 500) {
      errors['description'] = 'Description must be less than 500 characters';
    } else {
      errors.remove('description');
    }
    
    state = state.copyWith(
      description: description,
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
```

---

## Error Display

### Error Message Patterns

```dart
// Consistent error message display
class ErrorDisplayWidget extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;
  
  const ErrorDisplayWidget({
    super.key,
    this.error,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    if (error == null) return SizedBox.shrink();
    
    return Container(
      decoration: DecorationStyles.errorContainer(),
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              style: Theme.of(context).extension<CustomTextStyles>()!.errorMessage,
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }
}
```

### Form Error Display

```dart
// Form-level error display
class FormErrorDisplay extends StatelessWidget {
  final Map<String, String> errors;
  
  const FormErrorDisplay({
    super.key,
    required this.errors,
  });
  
  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return SizedBox.shrink();
    
    return Container(
      decoration: DecorationStyles.errorContainer(),
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please fix the following errors:',
            style: Theme.of(context).extension<CustomTextStyles>()!.errorMessage.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          ...errors.entries.map((entry) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${entry.value}',
              style: Theme.of(context).extension<CustomTextStyles>()!.errorMessage,
            ),
          )),
        ],
      ),
    );
  }
}
```

### Field-level Error Display

```dart
// Field-level error display in form fields
class AppTextFormField extends StatelessWidget {
  final String? Function(String?)? validator;
  final String? errorText;
  
  const AppTextFormField({
    super.key,
    this.validator,
    this.errorText,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      decoration: InputDecoration(
        errorText: errorText,
        errorStyle: Theme.of(context).extension<CustomTextStyles>()!.errorMessage,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
```

---

## Autofill Prevention

### Preventing Password Manager Popups

```dart
// Prevent unwanted password manager popups
class AppPasswordField extends StatefulWidget {
  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;
  
  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: TextFormField(
        obscureText: _obscureText,
        autofillHints: const [], // Prevent autofill
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
    );
  }
}
```

### Preventing Email Autofill

```dart
// Prevent email autofill in non-login forms
class AppEmailField extends StatelessWidget {
  final bool preventAutofill;
  
  const AppEmailField({
    super.key,
    this.preventAutofill = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      autofillHints: preventAutofill ? const [] : const [AutofillHints.email],
      autocorrect: false,
      enableSuggestions: !preventAutofill,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
      ),
    );
  }
}
```

### Form-level Autofill Prevention

```dart
// Prevent autofill for entire forms
class CreateTeamForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<CreateTeamForm> createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends ConsumerState<CreateTeamForm> {
  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        child: Column(
          children: [
            AppTextField(
              labelText: 'Team Name',
              autofillHints: const [], // Prevent autofill
              autocorrect: false,
              enableSuggestions: false,
            ),
            AppTextField(
              labelText: 'Description',
              autofillHints: const [], // Prevent autofill
              autocorrect: false,
              enableSuggestions: false,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Accessibility

### Semantic Labels

```dart
// Provide semantic labels for screen readers
class AccessibleFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  
  const AccessibleFormField({
    super.key,
    required this.label,
    this.hint,
    this.error,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: error,
        ),
      ),
    );
  }
}
```

### Focus Management

```dart
// Manage focus for better accessibility
class FocusManagementForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<FocusManagementForm> createState() => _FocusManagementFormState();
}

class _FocusManagementFormState extends ConsumerState<FocusManagementForm> {
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  void _submitForm() {
    if (_nameController.text.isEmpty) {
      _nameFocusNode.requestFocus();
      return;
    }
    
    if (_emailController.text.isEmpty) {
      _emailFocusNode.requestFocus();
      return;
    }
    
    // Form is valid, proceed
    _submitData();
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            decoration: InputDecoration(labelText: 'Name'),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
          ),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            decoration: InputDecoration(labelText: 'Email'),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitForm(),
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

### Error Announcements

```dart
// Announce errors to screen readers
class AccessibleErrorDisplay extends StatelessWidget {
  final String? error;
  
  const AccessibleErrorDisplay({
    super.key,
    this.error,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: error != null
          ? Container(
              key: ValueKey(error),
              decoration: DecorationStyles.errorContainer(),
              padding: EdgeInsets.all(12),
              child: Text(
                error!,
                style: Theme.of(context).extension<CustomTextStyles>()!.errorMessage,
              ),
            )
          : SizedBox.shrink(),
      ),
    );
  }
}
```

---

## Form Patterns

### Bottom Sheets vs Dialogs

**When to Use Full-Screen Bottom Sheets:**
- Forms with multiple input fields (player creation, game creation)
- Forms that need significant vertical space
- Forms with conditional fields that may expand
- Mobile-first UX where more screen space is beneficial

**When to Use Small Dialogs:**
- Quick confirmations (yes/no)
- Simple alerts
- Single-field inputs
- Destructive action confirmations

### Full-Screen Bottom Sheet Pattern

All data entry forms in HackTracker use full-screen bottom sheets for better mobile UX:

```dart
// Open a form as a full-screen bottom sheet
await showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // Allow full height
  backgroundColor: Colors.transparent,  // For rounded corners
  enableDrag: true,  // Allow swipe down to close
  builder: (_) => PlayerFormDialog(teamId: teamId),
);
```

**Form Widget Structure:**

```dart
class PlayerFormDialog extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Top padding to clear iPhone notch/Dynamic Island
      padding: const EdgeInsets.only(top: 50),
      // Rounded top corners
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // AppBar with close button
        appBar: AppBar(
          title: Text('Add Player'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // Scrollable form content
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Form fields here
            ],
          ),
        ),
        // Fixed action buttons at bottom
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('SAVE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Key Implementation Details:**
- `padding: const EdgeInsets.only(top: 50)` on the outer Container ensures the title and close button are positioned below the iPhone notch/Dynamic Island
- `bottomNavigationBar` uses `MediaQuery.of(context).padding.bottom` to respect safe area at bottom of screen
- Forms remain draggable with `enableDrag: true` in `showModalBottomSheet`
- Transparent backgrounds allow for rounded top corners to show properly

**Benefits:**
- ✅ More space for form fields
- ✅ Better mobile experience
- ✅ Scrollable content with fixed actions
- ✅ Swipe down to dismiss
- ✅ Keyboard doesn't cover inputs
- ✅ Consistent AppBar with close button

**Current Forms Using Bottom Sheets:**
- `PlayerFormDialog` - Add/edit players
- `GameFormDialog` - Create/edit games

---

### Create Team Form

```dart
class CreateTeamForm extends ConsumerStatefulWidget {
  final Function(String name, String? description) onSubmit;
  
  const CreateTeamForm({
    super.key,
    required this.onSubmit,
  });
  
  @override
  ConsumerState<CreateTeamForm> createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends ConsumerState<CreateTeamForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameController.text.trim(),
        _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            controller: _nameController,
            labelText: 'Team Name',
            hintText: 'Enter team name',
            validator: FormValidators.validateTeamName,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 16),
          AppTextFormField(
            controller: _descController,
            labelText: 'Description',
            hintText: 'Enter team description (optional)',
            maxLines: 3,
            validator: (value) {
              if (value != null && value.length > 500) {
                return 'Description must be less than 500 characters';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
```

### Player Form

```dart
class PlayerForm extends ConsumerStatefulWidget {
  final Player? player;
  final Function(PlayerFormData data) onSubmit;
  
  const PlayerForm({
    super.key,
    this.player,
    required this.onSubmit,
  });
  
  @override
  ConsumerState<PlayerForm> createState() => _PlayerFormState();
}

class _PlayerFormState extends ConsumerState<PlayerForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _playerNumberController = TextEditingController();
  String _selectedStatus = 'active';
  
  @override
  void initState() {
    super.initState();
    if (widget.player != null) {
      _firstNameController.text = widget.player!.firstName;
      _lastNameController.text = widget.player!.lastName ?? '';
      _playerNumberController.text = widget.player!.playerNumber?.toString() ?? '';
      _selectedStatus = widget.player!.status;
    }
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _playerNumberController.dispose();
    super.dispose();
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = PlayerFormData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty 
          ? null 
          : _lastNameController.text.trim(),
        playerNumber: _playerNumberController.text.trim().isEmpty 
          ? null 
          : int.parse(_playerNumberController.text.trim()),
        status: _selectedStatus,
      );
      
      widget.onSubmit(data);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            controller: _firstNameController,
            labelText: 'First Name',
            hintText: 'Enter first name',
            validator: (value) => FormValidators.validatePlayerName(value, 'First name'),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 16),
          AppTextFormField(
            controller: _lastNameController,
            labelText: 'Last Name',
            hintText: 'Enter last name (optional)',
            validator: (value) => value != null && value.isNotEmpty 
              ? FormValidators.validatePlayerName(value, 'Last name')
              : null,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 16),
          AppTextFormField(
            controller: _playerNumberController,
            labelText: 'Player Number',
            hintText: 'Enter player number (0-99)',
            keyboardType: TextInputType.number,
            validator: FormValidators.validatePlayerNumber,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 16),
          AppDropdownFormField<String>(
            value: _selectedStatus,
            items: ['active', 'inactive', 'sub'],
            onChanged: (value) => setState(() => _selectedStatus = value ?? 'active'),
            hint: 'Select status',
          ),
        ],
      ),
    );
  }
}
```

### Login Form

```dart
class LoginForm extends ConsumerStatefulWidget {
  final Function(String email, String password) onSubmit;
  
  const LoginForm({
    super.key,
    required this.onSubmit,
  });
  
  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppEmailField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email',
            validator: FormValidators.validateEmail,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 16),
          AppPasswordField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitForm(),
          ),
        ],
      ),
    );
  }
}
```

---

## Testing Forms

### Form Validation Testing

```dart
void main() {
  group('Form Validation', () {
    test('should validate team name correctly', () {
      expect(FormValidators.validateTeamName(null), 'Team name is required');
      expect(FormValidators.validateTeamName(''), 'Team name is required');
      expect(FormValidators.validateTeamName('ab'), 'Team name must be at least 3 characters');
      expect(FormValidators.validateTeamName('a' * 51), 'Team name must be less than 50 characters');
      expect(FormValidators.validateTeamName('Team@Name'), 'Team name can only contain letters, numbers, and spaces');
      expect(FormValidators.validateTeamName('Valid Team Name'), null);
    });
    
    test('should validate email correctly', () {
      expect(FormValidators.validateEmail(null), 'Email is required');
      expect(FormValidators.validateEmail(''), 'Email is required');
      expect(FormValidators.validateEmail('invalid'), 'Please enter a valid email address');
      expect(FormValidators.validateEmail('test@example.com'), null);
    });
    
    test('should validate password correctly', () {
      expect(FormValidators.validatePassword(null), 'Password is required');
      expect(FormValidators.validatePassword(''), 'Password is required');
      expect(FormValidators.validatePassword('short'), 'Password must be at least 8 characters');
      expect(FormValidators.validatePassword('nouppercase123'), 'Password must contain uppercase, lowercase, and number');
      expect(FormValidators.validatePassword('ValidPass123'), null);
    });
  });
}
```

### Form Widget Testing

```dart
void main() {
  group('CreateTeamForm', () {
    testWidgets('should validate and submit form', (tester) async {
      bool submitted = false;
      String? submittedName;
      String? submittedDesc;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateTeamForm(
              onSubmit: (name, desc) {
                submitted = true;
                submittedName = name;
                submittedDesc = desc;
              },
            ),
          ),
        ),
      );
      
      // Enter valid data
      await tester.enterText(find.byType(AppTextFormField).first, 'Test Team');
      await tester.enterText(find.byType(AppTextFormField).last, 'Test Description');
      
      // Submit form
      await tester.tap(find.text('Create'));
      await tester.pump();
      
      // Verify submission
      expect(submitted, true);
      expect(submittedName, 'Test Team');
      expect(submittedDesc, 'Test Description');
    });
    
    testWidgets('should show validation errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateTeamForm(onSubmit: (_, __) {}),
          ),
        ),
      );
      
      // Submit empty form
      await tester.tap(find.text('Create'));
      await tester.pump();
      
      // Verify validation errors
      expect(find.text('Team name is required'), findsOneWidget);
    });
  });
}
```

### Form Integration Testing

```dart
void main() {
  group('Form Integration', () {
    testWidgets('should handle form submission with optimistic updates', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(MockApiService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CreateTeamForm(
                onSubmit: (name, desc) {
                  // Simulate optimistic update
                },
              ),
            ),
          ),
        ),
      );
      
      // Fill form
      await tester.enterText(find.byType(AppTextFormField).first, 'New Team');
      
      // Submit
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      
      // Verify optimistic update
      expect(find.text('New Team'), findsOneWidget);
    });
  });
}
```

---

## Summary

HackTracker's form handling provides:

- **Comprehensive Validation** - Consistent validation functions for all input types
- **Form State Management** - GlobalKey pattern with Riverpod integration
- **Error Display** - Consistent error messaging and display patterns
- **Autofill Prevention** - Prevents unwanted password manager popups
- **Accessibility** - Semantic labels, focus management, and error announcements
- **Form Patterns** - Reusable patterns for common forms (team, player, login)
- **Testing Support** - Comprehensive testing patterns for forms and validation

The form handling system provides a **robust foundation** for user input with **consistent validation**, **error handling**, and **accessibility** support while maintaining **type safety** and **user experience** standards.
