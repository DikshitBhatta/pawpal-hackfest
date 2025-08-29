import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const StepProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? Colors.white
                              : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent ? Colors.green : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  if (index != totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 4,
                        color: isCompleted
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                stepLabels[index],
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.grey.shade300,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }
}
