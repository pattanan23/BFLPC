// menu_utils.dart
import 'package:flutter/material.dart';
import 'package:pallet_barcode/login_page.dart';

void showCustomMenu(BuildContext context, Offset position) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(40, 40),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.note_add),
          title: Text('New Form'),
          onTap: () {
            Navigator.pop(context);
            // new form action
          },
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.save),
          title: Text('Save Form'),
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.print),
          title: Text('Print'),
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('Exit'),
          onTap: () {
            Navigator.pop(context); // ปิด popup menu ก่อน // Close the popup menu first.
            Future.delayed(Duration.zero, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            });
          },
        ),
      ),
    ],
  );
}

void showEditSubMenu(BuildContext context, Offset position) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(40, 40),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.update),
          title: Text('Update Form'),
          onTap: () {
            Navigator.pop(context);
            // update form action
          },
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.delete),
          title: Text('Delete Form'),
          onTap: () {
            Navigator.pop(context);
            // delete form action
          },
        ),
      ),
    ],
  );
}
