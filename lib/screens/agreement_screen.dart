import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import '../services/agreement_service.dart';
import '../models/user_model.dart';

class AgreementScreen extends StatefulWidget {
  final UserModel tester;
  final String? agreementId;

  const AgreementScreen({
    super.key,
    required this.tester,
    this.agreementId,
  });

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  final AgreementService _agreementService = AgreementService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _currentAgreementId;

  @override
  void initState() {
    super.initState();
    _currentAgreementId = widget.agreementId;
    if (_currentAgreementId == null) {
      _createAgreement();
    }
  }

  Future<void> _createAgreement() async {
    final id = await _agreementService.createAgreement(widget.tester.userId);
    setState(() => _currentAgreementId = id);
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Co-ownership Agreement',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.description, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'CO-OWNERSHIP AGREEMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Testing Access Agreement',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tester Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tester Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    _InfoRow('Email', widget.tester.email),
                    _InfoRow('Role', widget.tester.role),
                    _InfoRow(
                      'Date',
                      DateTime.now().toString().substring(0, 10),
                    ),
                    _InfoRow('Agreement ID', _currentAgreementId ?? 'Generating...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Agreement Terms
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    _TermItem(
                      number: '1',
                      title: 'Testing Purpose Only',
                      description:
                      'Access is granted strictly for testing purposes. The tester agrees not to use the app for any commercial or personal purposes outside of testing.',
                    ),
                    _TermItem(
                      number: '2',
                      title: 'Confidentiality',
                      description:
                      'All information, features, and data accessed during testing must be kept strictly confidential and not shared with third parties.',
                    ),
                    _TermItem(
                      number: '3',
                      title: 'Owner Authority',
                      description:
                      'The owner retains full authority to revoke testing access at any time without prior notice or reason.',
                    ),
                    _TermItem(
                      number: '4',
                      title: 'Data Ownership',
                      description:
                      'All data, code, and intellectual property remains the exclusive property of the owner. The tester has no claim to any part of the application.',
                    ),
                    _TermItem(
                      number: '5',
                      title: 'Co-ownership Slip',
                      description:
                      'This signed agreement serves as a co-ownership slip confirming the tester\'s authorized testing access. It can be withdrawn by the owner at any time.',
                    ),
                    _TermItem(
                      number: '6',
                      title: 'Feedback & Reporting',
                      description:
                      'The tester agrees to provide honest feedback and report any bugs or issues discovered during testing.',
                    ),
                    _TermItem(
                      number: '7',
                      title: 'Compliance',
                      description:
                      'The tester agrees to comply with all applicable laws and regulations while using the application.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Agreement Checkbox
            Card(
              child: CheckboxListTile(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() => _agreedToTerms = value ?? false);
                },
                title: const Text(
                  'I have read and agree to all terms and conditions stated above.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                activeColor: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),

            // Signature Pad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Digital Signature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _signatureController.clear(),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    const Text(
                      'Please sign below:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Signature(
                        controller: _signatureController,
                        height: 150,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Draw your signature above',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_agreedToTerms && !_isLoading)
                    ? _submitAgreement
                    : null,
                icon: const Icon(Icons.draw, color: Colors.white),
                label: Text(
                  _isLoading ? 'Signing...' : 'Sign & Submit Agreement',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAgreement() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide your signature!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentAgreementId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agreement not ready. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert signature to base64
      final signatureImage = await _signatureController.toPngBytes();
      final signatureBase64 = base64Encode(signatureImage!);

      final success = await _agreementService.signAgreement(
        agreementId: _currentAgreementId!,
        signature: signatureBase64,
        ipAddress: '0.0.0.0',
      );

      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sign agreement. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Submit agreement error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Agreement Signed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The co-ownership agreement has been successfully signed and saved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Agreement ID: ${_currentAgreementId?.substring(0, 8)}...',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _TermItem({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[800],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}