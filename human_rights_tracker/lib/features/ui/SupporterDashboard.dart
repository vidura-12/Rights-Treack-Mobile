import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupporterDashboard extends StatefulWidget {
  final bool isDarkTheme;

  const SupporterDashboard({super.key, required this.isDarkTheme});

  @override
  State<SupporterDashboard> createState() => _SupporterDashboardState();
}

class _SupporterDashboardState extends State<SupporterDashboard> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  String _currentUserEmail = '';
  bool _isSupporter = false;

  // Modern theme colors
  Color get _backgroundColor => widget.isDarkTheme ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC);
  Color get _cardColor => widget.isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _accentColor => const Color(0xFF6366F1);
  Color get _inputBackgroundColor => widget.isDarkTheme ? const Color(0xFF1C2128) : Colors.white;

  final List<String> _statuses = [
    'reported',
    'open',
    'in progress',
    'investigation',
    'in court',
    'resolved',
    'closed',
  ];

  @override
  void initState() {
    super.initState();
    _currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserEmail = user.email ?? '';
      _isSupporter = _checkIfSupporter(_currentUserEmail);
    }
  }
    bool _checkIfSupporter(String email) {
    return email.contains('support') || 
           email.contains('admin') ||
           email.endsWith('@support.org') ||
           email.endsWith('@admin.org') ||
           email == 'viduranirmal1@gmail.com'; // Add your test emails
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return const Color(0xFF8B5CF6);
      case 'open':
        return const Color(0xFFF59E0B);
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'investigation':
        return const Color(0xFF8B5CF6);
      case 'in court':
        return const Color(0xFFEF4444);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return Icons.report;
      case 'open':
        return Icons.folder_open;
      case 'in progress':
        return Icons.pending_actions;
      case 'investigation':
        return Icons.search;
      case 'in court':
        return Icons.gavel;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.folder;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: _textColor),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supporter Dashboard',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentUserEmail,
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 20),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.logout, color: _textColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/loginAdmin');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: _cardColor,
            child: Column(
              children: [
                // Search bar
                TextField(
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    hintText: 'Search cases by ID, location, or type...',
                    hintStyle: TextStyle(color: _secondaryTextColor),
                    prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                    filled: true,
                    fillColor: _inputBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.isDarkTheme
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.isDarkTheme
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter chips - Updated to include 'assigned'
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Cases'),
                      const SizedBox(width: 8),
                      _buildFilterChip('assigned', 'My Cases'),
                      const SizedBox(width: 8),
                      _buildFilterChip('reported', 'Reported'),
                      const SizedBox(width: 8),
                      _buildFilterChip('open', 'Open'),
                      const SizedBox(width: 8),
                      _buildFilterChip('in progress', 'In Progress'),
                      const SizedBox(width: 8),
                      _buildFilterChip('investigation', 'Investigation'),
                      const SizedBox(width: 8),
                      _buildFilterChip('in court', 'In Court'),
                      const SizedBox(width: 8),
                      _buildFilterChip('resolved', 'Resolved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('closed', 'Closed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cases List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getCasesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: _secondaryTextColor),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading cases',
                          style: TextStyle(color: _textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _secondaryTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                final cases = snapshot.data?.docs ?? [];
                final filteredCases = cases.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? 'reported').toString().toLowerCase();
                  final caseNumber = (data['caseNumber'] ?? '').toString().toLowerCase();
                  final location = (data['location'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString().toLowerCase();
                  final assignedTo = (data['assignedTo'] ?? '').toString();

                  // Apply status filter
                  if (_selectedFilter != 'all') {
                    if (_selectedFilter == 'assigned') {
                      // Show only cases assigned to current supporter
                      if (assignedTo != _currentUserEmail) {
                        return false;
                      }
                    } else if (status != _selectedFilter) {
                      return false;
                    }
                  }

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    return caseNumber.contains(_searchQuery) ||
                        location.contains(_searchQuery) ||
                        category.contains(_searchQuery);
                  }

                  return true;
                }).toList();

                if (filteredCases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: _secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'assigned' 
                            ? 'No assigned cases'
                            : 'No cases found',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == 'assigned'
                            ? 'Cases assigned to you will appear here'
                            : 'Try adjusting your filters',
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCases.length,
                  itemBuilder: (context, index) {
                    final caseDoc = filteredCases[index];
                    final caseData = caseDoc.data() as Map<String, dynamic>;
                    return _buildCaseCard(caseDoc.id, caseData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                )
              : null,
          color: isSelected ? null : (widget.isDarkTheme ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCaseCard(String caseId, Map<String, dynamic> caseData) {
    final status = (caseData['status'] ?? 'reported').toString();
    final caseNumber = caseData['caseNumber'] ?? 'N/A';
    final category = caseData['category'] ?? 'Unknown';
    final location = caseData['location'] ?? 'Unknown';
    final assignedTo = caseData['assignedTo'] ?? '';
    final isAssignedToMe = assignedTo == _currentUserEmail;
    final reportedDate = caseData['createdAt'] != null
        ? (caseData['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isAssignedToMe 
            ? Border.all(color: _accentColor, width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Case #$caseNumber',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                      if (isAssignedToMe) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 12, color: _accentColor),
                            const SizedBox(width: 4),
                            Text(
                              'Assigned to you',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (assignedTo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: _secondaryTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(color: _textColor, fontSize: 14),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 16, color: _secondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      '${reportedDate.day}/${reportedDate.month}/${reportedDate.year}',
                      style: TextStyle(color: _textColor, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: _secondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      'Victim: ${caseData['victimGender'] ?? 'Unknown'}',
                      style: TextStyle(color: _textColor, fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.person_off, size: 16, color: _secondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      'Abuser: ${caseData['abuserGender'] ?? 'Unknown'}',
                      style: TextStyle(color: _textColor, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCaseDetails(caseId, caseData),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(color: _accentColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showUpdateStatusDialog(caseId, caseData),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(isAssignedToMe ? 'Update' : 'Assign'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAssignedToMe ? _accentColor : Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getCasesStream() {
    try {
      return FirebaseFirestore.instance
          .collection('cases')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error creating cases stream: $e');
      return const Stream<QuerySnapshot>.empty();
    }
  }

  void _showCaseDetails(String caseId, Map<String, dynamic> caseData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _secondaryTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Case Details',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Case Number', caseData['caseNumber'] ?? 'N/A'),
              _buildDetailRow('Category', caseData['category'] ?? 'Unknown'),
              _buildDetailRow('Location', caseData['location'] ?? 'Unknown'),
              _buildDetailRow('Victim Gender', caseData['victimGender'] ?? 'Unknown'),
              _buildDetailRow('Abuser Gender', caseData['abuserGender'] ?? 'Unknown'),
              _buildDetailRow('Description', caseData['description'] ?? 'No description'),
              _buildDetailRow('Status', caseData['status'] ?? 'reported'),
              _buildDetailRow('From Date', _formatDate(caseData['fromDate'])),
              _buildDetailRow('To Date', _formatDate(caseData['toDate'])),
              _buildDetailRow('Reported By', caseData['reportedByEmail'] ?? 'Unknown'),
              if (caseData['assignedTo'] != null && caseData['assignedTo'].toString().isNotEmpty) 
                _buildDetailRow('Assigned To', caseData['assignedTo']),
              
              // Status History
              if (caseData['statusHistory'] != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Status History',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...((caseData['statusHistory'] as List).map((history) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDarkTheme ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(history['status']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                history['status'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTimestamp(history['timestamp']),
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        if (history['note'] != null && history['note'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            history['note'],
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        Text(
                          'By: ${history['updatedBy'] ?? 'System'}',
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: _textColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(String caseId, Map<String, dynamic> caseData) {
    String selectedStatus = caseData['status'] ?? 'reported';
    final TextEditingController noteController = TextEditingController();
    final assignedTo = caseData['assignedTo'] ?? '';
    final isAssignedToMe = assignedTo == _currentUserEmail;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isAssignedToMe ? 'Update Case Status' : 'Assign Case',
            style: TextStyle(color: _textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case #${caseData['caseNumber']}',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (!isAssignedToMe) ...[
                  Text(
                    'Assign to yourself?',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By assigning this case, you will be responsible for handling it.',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Text(
                  'Select Status',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statuses.map((status) {
                    final isSelected = selectedStatus == status;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedStatus = status;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getStatusColor(status)
                              : _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              size: 16,
                              color: isSelected ? Colors.white : _getStatusColor(status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: TextStyle(
                                color: isSelected ? Colors.white : _getStatusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Progress Note',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  style: TextStyle(color: _textColor),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isAssignedToMe 
                      ? 'Add details about the progress...'
                      : 'Add initial notes about this case...',
                    hintStyle: TextStyle(color: _secondaryTextColor),
                    filled: true,
                    fillColor: _inputBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.isDarkTheme
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.isDarkTheme
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _secondaryTextColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!isAssignedToMe) {
                  // Assign case to current supporter
                  await _assignCaseToMe(caseId, selectedStatus, noteController.text.trim(), caseData);
                } else {
                  // Update case status
                  await _updateCaseStatus(caseId, selectedStatus, noteController.text.trim(), caseData);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAssignedToMe ? _accentColor : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isAssignedToMe ? 'Update' : 'Assign & Update'),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _assignCaseToMe(String caseId, String newStatus, String note, Map<String, dynamic> caseData) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

   final statusUpdate = {
  'status': newStatus,
  'timestamp': Timestamp.now(), // ✅ fixed
  'note': note.isNotEmpty ? note : 'Case assigned to supporter',
  'updatedBy': currentUser.email,
};

    await FirebaseFirestore.instance.collection('cases').doc(caseId).update({
      'status': newStatus,
      'assignedTo': currentUser.email,
      'lastUpdated': FieldValue.serverTimestamp(), // FIXED: Correct spelling
      'statusHistory': FieldValue.arrayUnion([statusUpdate]),
    });

    // Send notification to case owner
    final reportedByEmail = caseData['reportedByEmail'];
    if (reportedByEmail != null) {
      await _sendNotification(
        caseId: caseId,
        caseNumber: caseData['caseNumber'] ?? 'Unknown',
        newStatus: newStatus,
        reportedByEmail: reportedByEmail,
        isAssignment: true,
        assignedTo: currentUser.email,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Case assigned to you successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  } catch (e) {
    debugPrint('Error assigning case: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error assigning case: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

Future<void> _updateCaseStatus(String caseId, String newStatus, String note, Map<String, dynamic> caseData) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final statusUpdate = {
      'status': newStatus,
      'timestamp': FieldValue.serverTimestamp(), // FIXED: Correct spelling
      'note': note,
      'updatedBy': currentUser.email,
    };

    await FirebaseFirestore.instance.collection('cases').doc(caseId).update({
      'status': newStatus,
      'lastUpdated': FieldValue.serverTimestamp(), // FIXED: Correct spelling
      'statusHistory': FieldValue.arrayUnion([statusUpdate]),
    });

    // Send notification to case owner
    final reportedByEmail = caseData['reportedByEmail'];
    if (reportedByEmail != null) {
      await _sendNotification(
        caseId: caseId,
        caseNumber: caseData['caseNumber'] ?? 'Unknown',
        newStatus: newStatus,
        reportedByEmail: reportedByEmail,
        isAssignment: false,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Case status updated successfully'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  } catch (e) {
    debugPrint('Error updating status: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error updating status: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
Future<void> _sendNotification({
  required String caseId,
  required String caseNumber,
  required String newStatus,
  required String reportedByEmail,
  bool isAssignment = false,
  String? assignedTo,
}) async {
  try {
    String title, message;

    if (isAssignment) {
      title = 'Case Assigned';
      message = 'Your case #$caseNumber has been assigned to $assignedTo and status changed to: $newStatus';
    } else {
      title = 'Case Status Updated';
      message = 'Your case #$caseNumber status has been changed to: $newStatus';
    }

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': message,
      'type': 'status_update',
      'caseId': caseId,
      'reportedBy': reportedByEmail,
      'timestamp': FieldValue.serverTimestamp(), // FIXED: Correct spelling
      'read': false,
    });
  } catch (e) {
    debugPrint('Error sending notification: $e');
  }
}

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      final DateTime dateTime = (timestamp as Timestamp).toDate();
      final Duration diff = DateTime.now().difference(dateTime);

      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    if (date is Timestamp) {
      final d = date.toDate();
      return "${d.day}/${d.month}/${d.year}";
    }
    if (date is String) {
      try {
        final d = DateTime.parse(date);
        return "${d.day}/${d.month}/${d.year}";
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }
}