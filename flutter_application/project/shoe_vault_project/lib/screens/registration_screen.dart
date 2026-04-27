import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoe_vault_project/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _errorCode = "";

  void navigateLogin() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  void navigateHome() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'home');
  }

  void register() async {
    setState(() {
      _isLoading = true;
      _errorCode = "";
    });

    try {
      await _authService.signUp(_emailController.text, _passwordController.text);
      navigateLogin();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorCode = e.code;
      });
    }catch (e) {
      setState(() {
        _errorCode = "An unexpected error occurred.";
      });
    }
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ListView(
            children: [
              const SizedBox(height: 48),
              Icon(Icons.lock_outline, size: 100, color: Colors.blue[200]),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(label: Text('Email')),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(label: Text('Password')),
              ),
              const SizedBox(height: 24),
              _errorCode != ""
                  ? Column(
                      children: [Text(_errorCode), const SizedBox(height: 24)],
                    )
                  : const SizedBox(height: 0),
              OutlinedButton(
                onPressed: register,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: navigateLogin,
                    child: const Text('Login'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}