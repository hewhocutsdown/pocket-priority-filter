import 'package:polymer/polymer.dart';

/**
 * A Polymer click counter element.
 */
@CustomTag('pocket-items')
class PocketItems extends PolymerElement {
  @published int count = 0;
  final List itemList = toObservable([]);

  PocketItems.created() : super.created() {
    
    itemList.add(new PocketItem());
  }
}

@CustomTag('pocket-item')
class PocketItem extends PolymerElement{
  final Map values = toObservable({});

  PocketItem() : super.created(){
    values["item_id"] = "356877113";
    values["resolved_id"] = "356877113";
    values["given_url"] = "http://www.jadaliyya.com/pages/index/11680/why-there-is-no-military-solution-to-the-syrian-co";
    values["given_title"] = "Why There Is No Military Solution to the Syrian Conflict";
    values["favorite"] = "1";
    values["status"] = "0";
    values["time_added"] = "1373899540";
    values["time_updated"] = "1374245282";
    values["time_read"] = "0";
    values["time_favorited"] = "1374245282";
    // What is sort_id?
    values["sort_id"] = 787;
    values["resolved_title"] = "Why There Is No Military Solution to the Syrian Conflict";
    values["resolved_url"] = "http://www.jadaliyya.com/pages/index/11680/why-there-is-no-military-solution-to-the-syrian-co";
    values["excerpt"] = "Today, as violence intensifies in Syria, external powers, including the United States, are openly debating direct intervention.";
    values["is_article"] = "1";
    values["is_index"] = "0";
    values["has_video"] = "0";
    values["has_image"] = "1";
    values["word_count"] = "2513";
  }
}