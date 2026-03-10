import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/session_controller.dart';
import '../pages/edit_session_page.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/loading_spinner.dart';
import '../widgets/session_card.dart';
import '../../services/plantation_api_client.dart';
import '../services/session_service.dart';

class SessionsListPage extends StatefulWidget {
  final String seasonId;

  const SessionsListPage({super.key, required this.seasonId});

  @override
  State<SessionsListPage> createState() => _SessionsListPageState();
}

class _SessionsListPageState extends State<SessionsListPage> {
  late SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController =
        SessionController(SessionService(PlantationApiClient()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionController.fetchSessions(widget.seasonId);
    });
  }

  Future<void> _refresh() async {
    await _sessionController.fetchSessions(widget.seasonId);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ChangeNotifierProvider.value(
        value: _sessionController,
        child: Consumer<SessionController>(
          builder: (context, sessionController, child) {
            if (sessionController.isLoading &&
                sessionController.sessions.isEmpty) {
              return const LoadingSpinner(message: 'Loading sessions...');
            }

            if (sessionController.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${sessionController.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final sessions = sessionController.sessions;

            if (sessions.isEmpty) {
              return const EmptyState(
                message:
                    'No harvesting sessions recorded yet.\nTap the + button below to add your first session.',
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
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditSessionPage(
                          sessionId: session.id,
                          seasonId: widget.seasonId,
                        ),
                      ),
                    );
                    if (mounted) {
                      _refresh();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
