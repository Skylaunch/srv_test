import 'package:firebase_database/firebase_database.dart';
import 'package:srv_test/data_providers/users_data_provider.dart';
import 'package:srv_test/models/item_model.dart';

class ItemsDataProvider {
  ItemsDataProvider({required this.usersDataProvider});

  final UsersDataProvider usersDataProvider;

  Future<List<ItemModel>> getItems(
    bool isFavoritesOnly,
  ) async {
    final unprocessedItems =
        await FirebaseDatabase.instance.ref().child("Items").once();

    List<ItemModel> resultItems = [];

    final currentUser = usersDataProvider.getCurrentUser();

    for (var unprocessedItem in unprocessedItems.snapshot.children) {
      final itemAsJson = unprocessedItem.value as Map<Object?, Object?>;

      final title = itemAsJson['title'] as String;
      final description = itemAsJson['description'] as String;
      final imagePath = itemAsJson['imagePath'] as String;
      final key = itemAsJson['key'] as String;

      if (!isFavoritesOnly ||
          currentUser != null && currentUser.isItemFavorite(key)) {
        resultItems.add(
          ItemModel(
            title: title,
            description: description,
            imagePath: imagePath,
            key: unprocessedItem.key,
          ),
        );
      }
    }

    return resultItems;
  }

  Future<void> updateUser(
    ItemModel currentItem,
  ) async {
    final unprocessedItems =
        await FirebaseDatabase.instance.ref().child("Items").once();

    final currentUser = usersDataProvider.getCurrentUser();

    String? key;
    for (var unprocessedItem in unprocessedItems.snapshot.children) {
      final userAsJson = unprocessedItem.value as Map<Object?, Object?>;

      if (userAsJson['title'] == currentItem.title &&
          userAsJson['description'] == currentItem.description) {
        key = unprocessedItem.key;
      }
    }

    if (key == null || currentUser?.key == null) {
      return;
    }

    List<String> newIds = currentUser!.favoritesIds;
    currentUser.isItemFavorite(key) ? newIds.remove(key) : newIds.add(key);

    final Map<String, String> updaitedFavoriteStatus = {
      'favorite_items_list': newIds.join(','),
    };

    FirebaseDatabase.instance
        .ref()
        .child("Users")
        .child(currentUser.key!)
        .update(updaitedFavoriteStatus);

    usersDataProvider
        .setCurrentUser(currentUser.copyWith(favoritesIds: newIds));
  }
}
