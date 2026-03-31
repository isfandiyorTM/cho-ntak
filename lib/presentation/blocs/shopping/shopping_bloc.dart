import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../data/datasources/local_database.dart';
import '../../../domain/entities/shopping_entity.dart';

part 'shopping_event.dart';
part 'shopping_state.dart';

class ShoppingBloc extends Bloc<ShoppingEvent, ShoppingState> {
  final LocalDatabase _db;
  final _uuid = const Uuid();

  ShoppingBloc(this._db) : super(ShoppingInitial()) {
    on<LoadShoppingLists>(_onLoad);
    on<CreateShoppingList>(_onCreate);
    on<UpdateShoppingList>(_onUpdateList);
    on<DeleteShoppingList>(_onDeleteList);
    on<AddShoppingItem>(_onAddItem);
    on<UpdateShoppingItem>(_onUpdateItem);
    on<ToggleShoppingItem>(_onToggle);
    on<DeleteShoppingItem>(_onDeleteItem);
    on<ClearCheckedItems>(_onClearChecked);
  }

  Future<void> _onLoad(
      LoadShoppingLists e, Emitter<ShoppingState> emit) async {
    emit(ShoppingLoading());
    try {
      final lists = await _fetchAll();
      emit(ShoppingLoaded(lists));
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<void> _onCreate(
      CreateShoppingList e, Emitter<ShoppingState> emit) async {
    try {
      await _db.insertShoppingList({
        'id':         _uuid.v4(),
        'title':      e.title,
        'emoji':      e.emoji,
        'created_at': DateTime.now().toIso8601String(),
      });
      add(LoadShoppingLists());
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<void> _onUpdateList(
      UpdateShoppingList e, Emitter<ShoppingState> emit) async {
    try {
      await _db.updateShoppingListTitle(e.id, e.title, e.emoji);
      add(LoadShoppingLists());
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<void> _onDeleteList(
      DeleteShoppingList e, Emitter<ShoppingState> emit) async {
    try {
      await _db.deleteShoppingList(e.id);
      add(LoadShoppingLists());
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<void> _onAddItem(
      AddShoppingItem e, Emitter<ShoppingState> emit) async {
    try {
      await _db.insertShoppingItem({
        'id':         _uuid.v4(),
        'list_id':    e.listId,
        'name':       e.name,
        'quantity':   e.quantity,
        'is_checked': 0,
        'sort_order': e.sortOrder,
      });
      add(LoadShoppingLists());
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<void> _onUpdateItem(
      UpdateShoppingItem e, Emitter<ShoppingState> emit) async {
    try {
      await _db.updateShoppingItem(e.id,
          name: e.name, quantity: e.quantity);
      add(LoadShoppingLists());
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<void> _onToggle(
      ToggleShoppingItem e, Emitter<ShoppingState> emit) async {
    // Optimistic update — update UI first, then DB
    final current = state;
    if (current is ShoppingLoaded) {
      final updated = current.lists.map((l) {
        if (l.id != e.listId) return l;
        return l.copyWith(
          items: l.items.map((i) {
            if (i.id != e.itemId) return i;
            return i.copyWith(isChecked: !i.isChecked);
          }).toList(),
        );
      }).toList();
      emit(ShoppingLoaded(updated));
    }
    try {
      final item = (state is ShoppingLoaded)
          ? (state as ShoppingLoaded).lists
          .expand((l) => l.items)
          .firstWhere((i) => i.id == e.itemId,
          orElse: () => ShoppingItemEntity(
              id: e.itemId, listId: e.listId, name: ''))
          : ShoppingItemEntity(id: e.itemId, listId: e.listId, name: '');
      await _db.updateShoppingItem(e.itemId,
          isChecked: item.isChecked); // already toggled in optimistic
      // No reload needed — already updated optimistically
    } catch (err) {
      // Revert on error
      add(LoadShoppingLists());
    }
  }

  Future<void> _onDeleteItem(
      DeleteShoppingItem e, Emitter<ShoppingState> emit) async {
    try {
      await _db.deleteShoppingItem(e.itemId);
      add(LoadShoppingLists());
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<void> _onClearChecked(
      ClearCheckedItems e, Emitter<ShoppingState> emit) async {
    try {
      await _db.clearCheckedItems(e.listId);
      add(LoadShoppingLists());
    } catch (err) {
      emit(ShoppingError(err.toString()));
    }
  }

  Future<List<ShoppingListEntity>> _fetchAll() async {
    final listRows = await _db.getShoppingLists();
    final lists = <ShoppingListEntity>[];
    for (final row in listRows) {
      final itemRows = await _db.getShoppingItems(row['id'] as String);
      final items = itemRows.map((r) => ShoppingItemEntity(
        id:        r['id']         as String,
        listId:    r['list_id']    as String,
        name:      r['name']       as String,
        quantity:  r['quantity']   as String?,
        isChecked: (r['is_checked'] as int) == 1,
        sortOrder: r['sort_order'] as int,
      )).toList();
      lists.add(ShoppingListEntity(
        id:        row['id']         as String,
        title:     row['title']      as String,
        emoji:     row['emoji']      as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        items:     items,
      ));
    }
    return lists;
  }
}