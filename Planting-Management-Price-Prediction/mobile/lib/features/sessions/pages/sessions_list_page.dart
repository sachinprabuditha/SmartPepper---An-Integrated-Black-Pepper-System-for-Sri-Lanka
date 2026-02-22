import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/session_controller.dart';
import '../models/session_model.dart';
import '../pages/edit_session_page.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../widgets/session_card.dart';

class SessionsListPage extends ConsumerStatefulWidget {
  final String seasonId;

  const SessionsListPage({super.key, required this.seasonId});

  @override
  ConsumerState<SessionsListPage> createState() => _SessionsListPageState();
}

class _SessionsListPageState extends ConsumerState<SessionsListPage> {
  @override
  Widget build(BuildContext context) {
    final sessionsState = ref.watch(sessionControllerProvider(widget.seasonId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sessionControllerProvider(widget.seasonId));
      },
      child: sessionsState.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyState(
              message: 'No harvesting sessions recorded yet.\nTap the + button below to add your first session.',
              icon: Icons.inventory_2_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return SessionCard(
                session: session,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditSessionPage(
                        sessionId: session.id,
                        seasonId: widget.seasonId,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(sessionControllerProvider(widget.seasonId));
                  }
                },
              );
            },
          );
        },
        loading: () => const LoadingSpinner(message: 'Loading sessions...'),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${error.toString()}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(sessionControllerProvider(widget.seasonId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

