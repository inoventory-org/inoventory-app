import 'package:injectable/injectable.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/inventory/lists/notifiers/InventoryListNotifier.dart';
import 'package:inoventory_ui/inventory/lists/overview/list_service.dart';

@Injectable()
class ItemListController {
  final listService = getIt<ListService>();

  final InventoryListNotifier listNotifier;

  ItemListController(@factoryParam InventoryList list)
      : listNotifier = InventoryListNotifier(list);

  Future<void> initialize() async {
    await listNotifier.initialize();
  }
}
