import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavBarActiveIndexNotifier extends Notifier<int> {
	@override
	int build() => 0;

	void setIndex(int index) {
		state = index;
	}
}

final navBarActiveIndexProvider =
		NotifierProvider<NavBarActiveIndexNotifier, int>(
			NavBarActiveIndexNotifier.new,
		);