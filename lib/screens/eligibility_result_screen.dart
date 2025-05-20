import 'package:flutter/material.dart';
import '../services/eligibility_service.dart';

class EligibilityResultScreen extends StatelessWidget {
  final Map<String, dynamic> eligibilityResult;

  const EligibilityResultScreen({
    Key? key,
    required this.eligibilityResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryOrange = Color(0xFFFF8C00);
    final Color darkGrey = Color(0xFF333333);

    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        title: Text(
          'Uygunluk Değerlendirmesi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sonuç kartı
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: eligibilityResult['isEligible'] ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        eligibilityResult['isEligible']
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: eligibilityResult['isEligible']
                            ? Colors.green
                            : Colors.red,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          eligibilityResult['isEligible']
                              ? 'Evcil Hayvan Sahiplenmeye Uygunsunuz!'
                              : 'Evcil Hayvan Sahiplenmeye Uygun Değilsiniz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Toplam Puan: ${eligibilityResult['score']}/100',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Detaylı analiz
            Text(
              'Detaylı Analiz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...eligibilityResult['analysis'].entries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      entry.value == 'Uygun' ? Icons.check : Icons.warning,
                      color: entry.value == 'Uygun' ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCategoryTitle(entry.key),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            SizedBox(height: 24),

            // Öneriler
            if (!eligibilityResult['isEligible'])
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Öneriler',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Evcil hayvan sahiplenmek için aşağıdaki kriterleri karşılamanız gerekmektedir:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    _buildRecommendationItem(
                      '18 yaşından büyük olmalısınız',
                      eligibilityResult['analysis']['age'] != 'Uygun',
                    ),
                    _buildRecommendationItem(
                      'Aylık geliriniz en az 5.000 TL olmalıdır',
                      eligibilityResult['analysis']['income'] != 'Uygun',
                    ),
                    _buildRecommendationItem(
                      'Uygun barınma koşullarınız olmalıdır',
                      eligibilityResult['analysis']['housing'] != 'Uygun',
                    ),
                    _buildRecommendationItem(
                      'Evcil hayvan deneyiminiz olmalıdır',
                      eligibilityResult['analysis']['experience'] != 'Uygun',
                    ),
                    _buildRecommendationItem(
                      'Aile durumunuz uygun olmalıdır',
                      eligibilityResult['analysis']['familyStatus'] != 'Uygun',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String text, bool isHighlighted) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.arrow_right,
            color: isHighlighted ? Colors.orange : Colors.white70,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isHighlighted ? Colors.orange : Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryTitle(String key) {
    switch (key) {
      case 'age':
        return 'Yaş Durumu';
      case 'income':
        return 'Gelir Durumu';
      case 'housing':
        return 'Barınma Durumu';
      case 'experience':
        return 'Evcil Hayvan Deneyimi';
      case 'familyStatus':
        return 'Aile Durumu';
      default:
        return key;
    }
  }
} 