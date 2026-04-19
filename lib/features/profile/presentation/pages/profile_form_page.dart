import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/adaptive_back_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../controllers/profile_form_controller.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadIfEdit);
  }

  Future<void> _loadIfEdit() async {
    if (Get.find<ProfileFormController>().isSignup) return;
    final auth = Get.find<AuthController>();
    final uid = auth.currentUser.value?.uid;
    if (uid == null) return;
    final profile = await Get.find<GetUserProfile>()(uid);
    if (!mounted || profile == null) return;
    setState(() {
      _name.text = profile.displayName;
      _email.text = profile.email ?? '';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await Get.find<ProfileFormController>().submit(
      displayName: _name.text,
      email: _email.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileFormController>();
    final title =
        c.isSignup ? AppStrings.completeProfile : AppStrings.editProfile;

    return Scaffold(
      appBar: AppBar(
        leading: adaptiveAppBarLeading(context),
        automaticallyImplyLeading: adaptiveAppBarImplyLeading(context),
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              c.isSignup
                  ? AppStrings.signupProfileSubtitle
                  : AppStrings.editProfileSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: AppStrings.fullName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 2) {
                        return AppStrings.enterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppStrings.emailOptional,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Obx(() {
              final ctrl = Get.find<ProfileFormController>();
              return FilledButton(
                onPressed: ctrl.loading.value ? null : _submit,
                child: ctrl.loading.value
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        ctrl.isSignup
                            ? AppStrings.continueLabel
                            : AppStrings.save,
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
