import 'package:firstflutterapp/config/router.dart';
import 'package:flutter/material.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';

class ReportBottomSheet extends StatefulWidget {
  final String postId;
  final Function(String)? onPostReported;

  const ReportBottomSheet({
    Key? key, 
    required this.postId,
    this.onPostReported,
  }) : super(key: key);

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  String? _selectedReason;

  final List<Map<String, String>> _reportReasons = [
    {'value': 'DISLIKE', 'label': 'Je n\'aime pas ce contenu'},
    {'value': 'HARASSMENT', 'label': 'Harcèlement'},
    {'value': 'SELF_HARM', 'label': 'Contenu incitant à l\'automutilation'},
    {'value': 'VIOLENCE', 'label': 'Violence'},
    {'value': 'RESTRICTED_ITEMS', 'label': 'Objets interdits'},
    {'value': 'NUDITY', 'label': 'Nudité'},
    {'value': 'SCAM', 'label': 'Arnaque'},
    {'value': 'MISINFORMATION', 'label': 'Désinformation'},
    {'value': 'ILLEGAL_CONTENT', 'label': 'Contenu illégal'},
  ];
  
  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une raison')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.request(
        method: 'POST',
        endpoint: '/posts/${widget.postId}/report',
        withAuth: true,
        body: {'reason': _selectedReason},
      );

      if (!mounted) return;

      if (response.success) {
        if (widget.onPostReported != null) {
          widget.onPostReported!(widget.postId);
        } else {
          print('ReportBottomSheet: ERREUR - callback onPostReported est null');
        }
        
        final sseProvider = Provider.of<SSEProvider>(context, listen: false);
        sseProvider.removePostLocally(widget.postId);
        
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${response.error ?? "Une erreur est survenue"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Signaler ce contenu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              // Subtitle
              Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Merci de sélectionner une raison pour le signalement:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Report reasons list
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reportReasons.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final reason = _reportReasons[index];
                    final isSelected = reason['value'] == _selectedReason;

                    return InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _selectedReason = reason['value'];
                              });
                              _submitReport();
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reason['label'] ?? '',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
