import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'show_snackbar.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  void toggleAuthMode() {
    setState(() {
      isLoginMode = !isLoginMode;
    });
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (isLoginMode) {
      if (email.isEmpty || password.isEmpty) {
        showSnackBar(context: context, message: 'Preencha todos os campos!');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String? errorMessage = await _authService.enterUser(email: email, password: password);
        if (errorMessage != null) {
          showSnackBar(context: context, message: errorMessage);
          return;
        }
        showSnackBar(
          context: context,
          message: 'Login realizado com sucesso!',
          isErro: false,
        );
        Navigator.pushReplacementNamed(context, '/spaceList');
      } catch (e) {
        showSnackBar(context: context, message: e.toString());
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {

      final name = nameController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();

      if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        showSnackBar(context: context, message: 'Preencha todos os campos!');
        return;
      }

      if (password != confirmPassword) {
        showSnackBar(context: context, message: 'As senhas não coincidem!');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String? errorMessage = await _authService.registerUser(
          email: email,
          password: password,
          name: name,
        );

        if (errorMessage != null) {
          showSnackBar(context: context, message: errorMessage);
          return;
        }

        showSnackBar(
          context: context,
          message: 'Conta criada com sucesso!',
          isErro: false,
        );

        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            isLoginMode = true;
          });
        });
      } catch (e) {
        showSnackBar(context: context, message: e.toString());
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void forgotMyPasswordClicked() {
    final email = emailController.text.trim();
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController resetPasswordController = TextEditingController(text: email);
        return AlertDialog(
          title: const Text("Confirme o e-mail para redefinição de senha"),
          content: TextFormField(
            controller: resetPasswordController,
            decoration: const InputDecoration(label: Text("Confirme o e-mail")),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _authService.resetPassword(email: resetPasswordController.text).then((String? erro) {
                  if (erro == null) {
                    showSnackBar(
                      context: context,
                      message: "E-mail de redefinição enviado!",
                      isErro: false,
                    );
                  } else {
                    showSnackBar(context: context, message: erro);
                  }
                  Navigator.pop(context);
                });
              },
              child: const Text("Redefinir senha"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5F6F52), Color(0xFFA9B388)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  color: const Color(0xFFF9EBC7),
                  elevation: 8.0,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLoginMode ? 'Bem-vindo!' : 'Criar Conta',
                          style: const TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF783D19),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        if (!isLoginMode)
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: const Icon(Icons.person, color: Color(0xFFC4651F)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFFFAE0),
                            ),
                          ),
                        if (!isLoginMode) const SizedBox(height: 16.0),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email, color: Color(0xFFC4651F)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFFAE0),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFFC4651F)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: const Color(0xFFC4651F),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFFAE0),
                          ),
                        ),
                        if (!isLoginMode) const SizedBox(height: 16.0),
                        if (!isLoginMode)
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirmar Senha',
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFFC4651F)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFFFAE0),
                            ),
                          ),
                        if (isLoginMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: forgotMyPasswordClicked,
                              child: const Text(
                                "Esqueci minha senha.",
                                style: TextStyle(color: Color(0xFFC4651F)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24.0),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC4651F),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48.0,
                                    vertical: 12.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                onPressed: _submit,
                                child: Text(
                                  isLoginMode ? 'Entrar' : 'Cadastrar',
                                  style: const TextStyle(fontSize: 16.0, color: Colors.white),
                                ),
                              ),
                        const SizedBox(height: 16.0),
                        TextButton(
                          onPressed: toggleAuthMode,
                          child: Text(
                            isLoginMode
                                ? 'Não tem uma conta? Crie agora'
                                : 'Já tem uma conta? Faça login',
                            style: const TextStyle(
                              color: Color(0xFF5F6F52),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
