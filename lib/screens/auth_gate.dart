import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/workflow_provider.dart';
import 'auth_screen.dart';
import 'workflow_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<WorkflowProvider>().loadAll();
        });
        return const WorkflowHomeScreen();
      },
    );
  }
}
