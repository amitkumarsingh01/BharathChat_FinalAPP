import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class WithdrawDiamond extends StatefulWidget {
  const WithdrawDiamond({Key? key}) : super(key: key);

  @override
  State<WithdrawDiamond> createState() => _WithdrawDiamondState();
}

class _WithdrawDiamondState extends State<WithdrawDiamond> {
  bool _isLoading = true;
  Map<String, dynamic>? _info;
  List<Map<String, dynamic>> _withdrawals = [];
  int? _userDiamonds;
  final _formKey = GlobalKey<FormState>();
  final _diamondController = TextEditingController();
  int _enteredDiamonds = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _diamondController.addListener(_onDiamondChanged);
  }

  void _onDiamondChanged() {
    final n = int.tryParse(_diamondController.text);
    setState(() {
      _enteredDiamonds = n ?? 0;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = ApiService.currentUserId;
      if (userId == null) throw Exception('User not found');
      final info = await ApiService.getWithdrawStarInfo();
      final withdrawals = await ApiService.getUserStarWithdrawals(userId);
      final totalStars = await ApiService.getTotalStars(userId);
      setState(() {
        _info = info;
        _withdrawals = withdrawals;
        _userDiamonds = totalStars;
      });
    } catch (e) {
      setState(() {
        _info = null;
        _withdrawals = [];
        _userDiamonds = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
    });
    try {
      final userId = ApiService.currentUserId;
      if (userId == null) throw Exception('User not found');
      final starCount = int.parse(_diamondController.text);
      await ApiService.createWithdrawStar(userId: userId, starCount: starCount);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted!'),
          backgroundColor: Colors.green,
        ),
      );
      _diamondController.clear();
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit request'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  void dispose() {
    _diamondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Withdraw Stars',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_info == null || _userDiamonds == null) {
      return const Center(
        child: Text(
          'Failed to load data',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    final min = _info!['minimum_star'] ?? 0;
    final rate = _info!['conversion_rate'] ?? 1.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stars: $_userDiamonds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum to withdraw: $min',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Conversion rate: 1 Star = $rate',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          _userDiamonds! >= min
              ? _buildForm(min, rate)
              : Text(
                'You need at least $min stars to withdraw.',
                style: const TextStyle(color: Colors.red),
              ),
          const SizedBox(height: 30),
          const Text(
            'Your Withdrawal Requests:',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _withdrawals.isEmpty
              ? const Text(
                'No withdrawal requests yet.',
                style: TextStyle(color: Colors.white70),
              )
              : _buildWithdrawalsList(),
        ],
      ),
    );
  }

  Widget _buildForm(int min, double rate) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _diamondController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Stars to withdraw',
              labelStyle: TextStyle(color: Color(0xFFCACACA)),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter star count';
              final n = int.tryParse(value);
              if (n == null) return 'Enter a valid number';
              if (n < min) return 'Minimum is $min';
              if (_userDiamonds != null && n > _userDiamonds!)
                return 'You only have $_userDiamonds';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (_enteredDiamonds >= min)
            Text(
              'You will receive: ${(_enteredDiamonds * rate).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Request Withdrawal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsList() {
    final rate = _info != null ? (_info!['conversion_rate'] ?? 1.0) : 1.0;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _withdrawals.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white24),
      itemBuilder: (context, i) {
        final wd = _withdrawals[i];
        final stars = wd['star_count'] ?? 0;
        final amount = (stars * rate).toStringAsFixed(2);
        return ListTile(
          title: Text(
            'Stars: $stars  |  Amount: $amount',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Status: ${wd['status']}\nRequested: ${wd['created_at']}',
            style: const TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }
}
