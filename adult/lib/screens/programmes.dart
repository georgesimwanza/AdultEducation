import 'package:flutter/material.dart';
import '../Service/programme_service.dart';
import '../Model/programme_model.dart';

typedef Programme = ProgrammeModel;

const kPurple = Color(0xFF3D1870);
const kPurpleBg = Color(0xFFF3EFFE);
const kWhite = Colors.white;
const kGrey = Color(0xFFF6F6F6);

class ProgrammePage extends StatefulWidget {
  const ProgrammePage({super.key});

  @override
  State<ProgrammePage> createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  late Future<List<ProgrammeModel>> _programmesFuture;

  @override
  void initState() {
    super.initState();
    _programmesFuture = ProgrammeService().getProgrammes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: FutureBuilder<List<ProgrammeModel>>(
          future: _programmesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final programmes = snapshot.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  const Text(
                    'Popular Programmes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: programmes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.9,
                        ),
                    itemBuilder: (_, i) =>
                        _ProgrammeCard(programme: programmes[i]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgrammeCard extends StatelessWidget {
  final ProgrammeModel programme;
  const _ProgrammeCard({required this.programme});

  void _showDetail(BuildContext context) async {
    final navigator = Navigator.of(context); // capture before await

    final result = await showModalBottomSheet<ProgrammeModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProgrammeDetailSheet(programme: programme),
    );

    if (result != null) {
      navigator.pop(result); // use captured navigator
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, size: 40, color: kPurple),
                    const SizedBox(height: 10),
                    Text(
                      programme.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: kPurple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'ID: ${programme.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgrammeDetailSheet extends StatelessWidget {
  final ProgrammeModel programme;
  const _ProgrammeDetailSheet({required this.programme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            programme.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (programme.description != null) ...[
            const SizedBox(height: 8),
            Text(
              programme.description!,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, programme),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple,
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Enrol Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
