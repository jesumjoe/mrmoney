class BudgetStatusResult {
  final BudgetStatus status;
  final double remainingSafeAmount;
  final double potentialBalance;

  BudgetStatusResult({
    required this.status,
    required this.remainingSafeAmount,
    required this.potentialBalance,
  });
}

enum BudgetStatus { safe, warning, exceeded }

class BudgetService {
  // Calculate Safe to Spend
  // Safe = Current Balance - Savings Goal
  static double calculateSafeToSpend({
    required double currentBalance,
    required double savingsGoal,
  }) {
    return currentBalance - savingsGoal;
  }

  // Calculate projected spending for the month based on daily average
  static double calculateProjectedSpending({
    required double currentSpent,
    required DateTime currentMonth,
  }) {
    final now = DateTime.now();
    if (now.month != currentMonth.month || now.year != currentMonth.year) {
      return currentSpent; // Past month, projection is actual
    }

    final daysPassed = now.day;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    if (daysPassed == 0) return 0;

    final dailyAvg = currentSpent / daysPassed;
    return dailyAvg * totalDays;
  }

  // Check if a new expense will breach the Safe-to-Spend limit
  // Tolerance: 20% of Savings Goal
  static BudgetStatusResult checkGlobalBudgetStatus({
    required double currentBalance, // Income - Expense
    required double savingsGoal,
    required double newExpenseAmount,
  }) {
    final potentialBalance = currentBalance - newExpenseAmount;
    final safeToSpend = currentBalance - savingsGoal;
    final remainingSafeAmount = safeToSpend - newExpenseAmount;

    // Danger Zone: Dipping into savings
    if (potentialBalance < savingsGoal) {
      return BudgetStatusResult(
        status: BudgetStatus.exceeded,
        remainingSafeAmount: remainingSafeAmount,
        potentialBalance: potentialBalance,
      );
    }

    // Warning Zone: Within 20% of GOAL
    // i.e. Surplus is less than 20% of Goal
    // Example: Goal 5000. 20% = 1000.
    // If Surplus < 1000, WARN.
    final warningThreshold = savingsGoal * 0.2;
    // potentialBalance - savingsGoal = Surplus (New Safe to Spend)
    if ((potentialBalance - savingsGoal) <= warningThreshold) {
      return BudgetStatusResult(
        status: BudgetStatus.warning,
        remainingSafeAmount: remainingSafeAmount,
        potentialBalance: potentialBalance,
      );
    }

    return BudgetStatusResult(
      status: BudgetStatus.safe,
      remainingSafeAmount: remainingSafeAmount,
      potentialBalance: potentialBalance,
    );
  }

  static String getBudgetWarningMessage({
    required BudgetStatus status,
    required double remainingAfterExpense,
    required double savingsGoal,
  }) {
    if (status == BudgetStatus.exceeded) {
      // "⚠️ You're approaching your limit! After this expense, you'll have only ₹XXX left to spend this month while maintaining your ₹YYY savings goal."
      // Wait, if exceeded, they have BROKEN the goal.
      // "⚠️ You've exceeded your safe limit! This expense dips into your savings goal of ₹YYY by ₹ZZZ."
      final dip = (remainingAfterExpense).abs();
      return "⚠️ Critical: This expense dips into your savings goal of ₹${savingsGoal.toStringAsFixed(0)} by ₹${dip.toStringAsFixed(0)}!";
    } else if (status == BudgetStatus.warning) {
      return "⚠️ You're approaching your limit! After this expense, you'll have only ₹${remainingAfterExpense.toStringAsFixed(0)} left to spend this month while maintaining your ₹${savingsGoal.toStringAsFixed(0)} savings goal.";
    }
    return "";
  }

  // Calculate category budget status
  // Returns percentage used (0.0 to 1.0+)
  static double calculateCategoryUsage({
    required double spent,
    required double limit,
  }) {
    if (limit == 0) return 0;
    return spent / limit;
  }
}
