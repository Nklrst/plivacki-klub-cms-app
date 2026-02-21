import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podešavanja'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Promena Emaila'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Uskoro!')));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Promena Lozinke'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.pool_outlined),
            title: const Text('Podaci o Klubu'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Uskoro!')));
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool obscureOld = true;
        bool obscureNew = true;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Promena Lozinke'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Stara lozinka',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nova lozinka',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final oldPw = oldPasswordController.text.trim();
                  final newPw = newPasswordController.text.trim();

                  if (oldPw.isEmpty || newPw.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Popunite oba polja.')),
                    );
                    return;
                  }

                  try {
                    final apiClient = Provider.of<ApiClient>(
                      context,
                      listen: false,
                    );
                    await apiClient.dio.put(
                      '/users/me/password',
                      data: {'old_password': oldPw, 'new_password': newPw},
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lozinka je uspešno promenjena!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Greška: Stara lozinka nije tačna.'),
                      ),
                    );
                  }
                },
                child: const Text('Sačuvaj'),
              ),
            ],
          ),
        );
      },
    );
  }
}
