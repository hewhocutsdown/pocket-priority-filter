import 'package:polymer/polymer.dart';
import 'dart:async';
import 'dart:html';
import 'dart:core';
import 'dart:convert';

@CustomTag('pocket-item')
class PocketItem extends PolymerElement {
  String name;
  final Map<String,String> javaMap = toObservable({});
  final Map<String,String> serverMap = toObservable({});
  final List taskList = toObservable([]);

  PocketItem.created(): super.created(){
    this.name = this.attributes["name"];
    loadFromServer();
  }

  void loadFromServer()
  {
    Future future = new Future(IForms.getInstance().get_Status);

    future.then(updatePage);
  }
  void updatePage(Map<String,Object> fieldMap)
  {
    Map<String,String> javainfo = fieldMap["java"];
    javaMap.clear();
    javaMap.addAll(javainfo);

    Map<String,String> serverinfo = fieldMap["serverinfo"];
    serverMap.clear();
    serverMap.addAll(serverinfo);

    List<String> tasks = fieldMap["tasks"];
    this.taskList.clear();
    this.taskList.addAll(tasks);
  }

}


class IForms extends Connector
{
  static IForms instance;
  static IForms getInstance()
  {
    if(instance == null)
      instance = new IForms();
    return instance;
  }

  IForms(){}

  List<Setting> list_Settings_General()
  {
    try{
      String json = serverRequest("/iforms/json/list/settings/general");
      List<Setting> itemList = new List<Setting>();
      List<Map<String,String>> mapList = JSON.decode(json);
      for(Map<String,String> map in mapList)
        itemList.add(new Setting.fromMap(map));

      itemList.sort();
      return itemList;
    } on Exception catch (e)
    {
      throw new IFMMonitorServiceException.causedBy("Error Getting General Settings List", e);
    }
  }
  List<Setting> list_Settings_Advanced()
  {
    try{
      String json = serverRequest("/iforms/json/list/settings/advanced");
      List<Setting> itemList = new List<Setting>();
      List<Map<String,String>> mapList = JSON.decode(json);
      for(Map<String,String> map in mapList)
        itemList.add(new Setting.fromMap(map));

      itemList.sort();
      return itemList;
    } on Exception catch (e)
    {
      throw new IFMMonitorServiceException.causedBy("Error Getting Advanced Settings List", e);
    }
  }
  List<Environment> list_Environments()
  {
    try{
      String json = serverRequest("/iforms/json/list/environments", null,null,null);
      List<Environment> itemList = new List<Environment>();
      List<Map<String,String>> mapList = JSON.decode(json);
      for(Map<String,String> map in mapList)
        itemList.add(new Environment.fromMap(map));
      itemList.sort();
      return itemList;
    } on Exception catch (e)
    {
      throw new IFMMonitorServiceException.causedBy("Error Getting Environments List", e);
    }
  }
  void set_Setting(SettingBase setting)
  {
    try{
      if(setting.key != null)
        serverRequest("/iforms/update/setting", null,setting.getPostData(),"application/x-www-form-urlencoded; charset=UTF-8");
      else
        serverRequest("/iforms/create/setting", null,setting.getPostData(),"application/x-www-form-urlencoded; charset=UTF-8");
    } on Exception catch (e)
    {
      print(e.toString());
      throw new IFMMonitorServiceException.causedBy("Error Setting Setting", e);
    }
  }
  void delete_Setting(String key)
  {
    try{
      Map<String,String> parameters = new Map<String,String>();
      parameters["KEY"] = key;
      serverRequest("/iforms/delete/setting", parameters,null,null);
    } on Exception catch (e)
    {
      throw new IFMMonitorServiceException.causedBy("Error Deleteing Setting", e);
    }
  }

  Map<String,Object> get_Status()
  {
    try{
      String json = serverRequest("/iforms/json/get/status", null,null,null);
      Map<String,Object> itemMap = JSON.decode(json);
      return itemMap;
    } on Exception catch (e)
    {
      throw new IFMMonitorServiceException.causedBy("Error Getting Status", e);
    }
  }
}


abstract class Connector
{
  ///get a string from the server.
  ///throws IFMMonitorServiceException on major error
  ///throws IFMServerError is server response is not 200
  String serverRequest(String url, [Map<String,String> parameters=null,String json=null,String contentType=null])
  {
    url = createURL(url,parameters);

    HttpRequest request;
    int status = null;
    String responseText = null;
    try{
    request = new HttpRequest();
    if(json == null)
    {
      request.open("GET", url, async : false);
      request.send();
    }
    else
    {
      request.open("POST", url, async : false);
      request.setRequestHeader("Content-Type", contentType);
      request.send(json);
    }


    status = request.status;
    responseText = request.responseText;

    } on Exception catch (e){
      throw new IFMMonitorServiceException.causedBy("Error Getting Server Resource " + url, e);
    }

    if(status != null && status != 200)
      throw new IFMServerException(responseText);

    return request.responseText;
  }

  ///convert a url and parameter map to a valid url string
  static String createURL(String url,Map<String,String> parameters)
  {
    if(parameters == null || parameters.isEmpty)
      return url;

    StringBuffer urlString = new StringBuffer(url);
    int keycount = 0;
    for(String key in parameters.keys)
    {
      if(parameters[key] == null || parameters[key] == "")
        continue;

      if(keycount++ == 0)
        urlString.write("?");
      else
        urlString.write("&");

      urlString.write(key.toUpperCase());
      urlString.write("=");
      urlString.write(Uri.encodeComponent(parameters[key]));
    }
    return urlString.toString();
  }
}


///IFMMonitorService exception object
 class IFMMonitorServiceException implements Exception {
  String cause;
  IFMMonitorServiceException(this.cause);
  IFMMonitorServiceException.causedBy(String message,Exception exception)
  {
    if(exception == null)
      this.cause = message;
    else
      this.cause = message + ". Caused By " + exception.toString();
  }

  String toString()
  {
    return cause;
  }
}
///iForms Server exception object
class IFMServerException extends IFMMonitorServiceException {
  IFMServerException(String cause): super(cause);
  IFMServerException.causedBy(String message,Exception exception): super.causedBy(message,exception);
}
class IFMArgumentException extends IFMMonitorServiceException {
  IFMArgumentException(String cause): super(cause);
  IFMArgumentException.causedBy(String message,Exception exception): super.causedBy(message,exception);
}

abstract class SettingBase implements Comparable<SettingBase>
{
  String key;
  String error;

  String getPostData();
  void resetValues();

  int compareTo(SettingBase other)
  {
    return this.key.compareTo(other.key);
  }
  int compare(SettingBase a, SettingBase b)
  {
    return a.key.compareTo(b.key);
  }
}



abstract class SettingPageBase extends PolymerElement {
  String name;
  bool autoblur = false;

  var lastStream;

  final List<SettingBase> itemList = toObservable([]);

  SettingPageBase() : super.created() {
    this.name = this.attributes["name"];
    loadFromServer();
  }

  ///load setting data from server.
  void loadFromServer();

  ///The outer div id of each setting should be the setting key.
  ///This method deletes that setting key when called.
  ///This is looking for element.parent.parent.id
  void onDelete(Event e, var detail, Node target)
  {
    Element element = target;
    String id = element.parent.parent.id;

    SettingBase remove;
    for(SettingBase setting in this.itemList)
      if(setting.key == id)
        remove = setting;

    if(remove != null)
    {
      try{
      IForms.getInstance().delete_Setting(remove.key);
      } on Exception catch(e){}
      this.loadFromServer();
    }
  }

  ///Hide "editableSetting" class and unhide "input" class
  ///focus on top input
  ///make sure class hide is defined
  void onClickToEdit(Event e, var detail, Node target)
  {
    Element element = target;

    List<DivElement> labels = element.parent.querySelectorAll(".editableSetting");
    for(DivElement label in labels)
    {
      label.classes.add("hide");
    }

    List<InputElement> inputElements = element.parent.querySelectorAll(".input");
    for(InputElement input in inputElements)
    {
      if(this.lastStream != null)
        this.lastStream.cancel();
      if(this.autoblur)
        this.lastStream = input.onBlur.listen(onblur);
      input.classes.remove("hide");
    }

    InputElement inputElement = element.parent.querySelector(".input");
    inputElement.focus();
  }

  ///if enter is pressed then submit is called
  ///if esc is pressed then blur setting
  void onEditableKeyup(KeyboardEvent e, var detail, Node target) {
    InputElement element = target;

    if(e.keyCode == KeyCode.ENTER)
    {
      FormElement form = element.parent;
      submit(null,null,form);
    }

    if (e.keyCode == KeyCode.ESC)
    {
      onblur(e);
    }
  }

  ///remove editable and revert changes.
  ///assumed structure <div id="<key>"><form>target element</form></div>
  void onblur(Event e){
    InputElement element = e.target;

    List<InputElement> inputElements = element.parent.querySelectorAll(".input");
    for(InputElement input in inputElements)
      input.classes.add("hide");
    for(SettingBase setting in this.itemList)
      if(setting.key == element.parent.parent.id)
        setting.resetValues();
    List<DivElement> labels = element.parent.querySelectorAll(".editableSetting");
    for(DivElement label in labels)
      label.classes.remove("hide");
  }

  ///Send setting changes to server.
  ///assumed structure <form name="<key>">target element</form>
  ///assumes that form parent also contains a div with class returnmsg.
  void submit(Event e, var detail, Node target)
  {
    if(e != null)
      e.preventDefault();
    FormElement element = target;
    String key = element.name;

      for(SettingBase setting in itemList)
      if(setting.key == key)
      {
        try{
          IForms.getInstance().set_Setting(setting);
          loadFromServer();
        } on IFMMonitorServiceException catch(e){
          setting.error = e.toString();
          Element returnElement = target.parent.querySelector(".returnmsg");
          returnElement.classes.remove("hide");
        }
      }
  }


}

@CustomTag('iforms-settings')
class Settings extends SettingPageBase {

  @observable String caption = "Settings";
  ///stores the last stream listener to prevent attaching multiple onblur events
  var lastStream;

  Settings.created() : super() {
    this.autoblur = true;
  }

  void loadFromServer()
  {
    Future future;
    switch(this.name)
    {
      case "general":
        Future future = new Future(IForms.getInstance().list_Settings_General);
        future.then(updatePage);
        break;
      case "advanced":
        Future future = new Future(IForms.getInstance().list_Settings_Advanced);
        this.caption = "Settings - Contact Support Before Modifying These Settings";
        future.then(updatePage);
        break;
      default:
        break;
    }
  }
  void updatePage(List<Setting> settings)
  {
    this.itemList.clear();
    this.itemList.addAll(settings);
  }

}

@CustomTag('iforms-setting')
class Setting extends SettingBase
{
   //String key; //in parent
   String value;
   String error = "";

   String description;
   Object originalValue;
   String type = "text";
   String stylesheet = "longform";

  Setting(String key,this.originalValue, this.description)
  {
    this.key = key;
    this.value = originalValue.toString();
    if(originalValue is int || originalValue is double)
    {
      this.type = "number";
      this.stylesheet = "shortform";
    }
  }

  Setting.fromMap(Map<String,Object> map)
  {
    this.originalValue = map["Value"];
    this.key = map["key"];
    this.description = map["Description"];

    if(this.originalValue is String)
    {
      this.value = this.originalValue;
      this.type = "text";
    }
    if(this.originalValue is int || this.originalValue is double)
    {
      this.value = this.originalValue.toString();
      this.type = "number";
      this.stylesheet = "shortform";
    }
    if(this.originalValue is bool)
    {
      this.value = this.originalValue.toString();
      this.type = "text";
    }
    if(this.originalValue is List<String>)
    {
      List<String> valueList = this.originalValue;
      this.value = valueList[0];
      this.originalValue = valueList[0];
      this.type = "text";
    }
    if(this.originalValue is Map<String,String>)
    {
      Map<String,String> valueMap = this.originalValue;
      this.value = valueMap["path"];
      this.originalValue = valueMap["path"];
      this.type = "text";
    }

    if(this.value == "")
    {
      this.value = "Click to edit";
      this.originalValue = "Click to edit";
    }
  }

  void resetValues()
  {
    this.value = this.originalValue;
  }

  String getPostData()
  {
    String urlKey = Uri.encodeComponent(this.key);
    String urlValue = Uri.encodeComponent(this.value);
    if(urlValue == "Click to edit")
      urlValue = "";

    return "KEY=$urlKey&VALUE=$urlValue";
  }
}

@CustomTag('iforms-environments')
class Environments extends SettingPageBase {

  @observable String caption = "Settings";
  ///stores the last stream listener to prevent attaching multiple onblur events
  var lastStream;

  Environments.created() : super() {
    this.autoblur = false;
  }

  void loadFromServer()
  {
    Future future = new Future(IForms.getInstance().list_Environments);
    future.then(updatePage);
  }
  void updatePage(List<Environment> settings)
  {
    this.itemList.clear();
    this.itemList.addAll(settings);
  }
}

@CustomTag('iforms-environment')
class Environment extends SettingBase
{
   //String key;//in parent
   String name;
   String path;
   @observable
   String error = "";

   String originalName;
   String originalPath;

   Environment(this.name,this.path)
  {
    this.key = null;
  }

  Environment.fromMap(Map<String,Object> map)
  {
    this.originalName = map["Name"];
    this.name = this.originalName;
    Map<String,String> pathMap = map["Path"];
    this.originalPath = pathMap["path"];
    this.path = this.originalPath;

    this.key = "report.environment.$name";

    if(this.name == "")
      this.name = "Click to edit";
    if(this.path == "")
      this.path = "Click to edit";
  }

  void resetValues()
  {
    this.name = this.originalName;
    this.path = this.originalPath;

    if(this.name == "")
      this.name = "Click to edit";
    if(this.path == "")
      this.path = "Click to edit";
  }

  String getPostData()
  {
    String urlKey = Uri.encodeComponent(this.key);
    String urlName = Uri.encodeComponent(this.name);
    String urlPath = Uri.encodeComponent(this.path);
    if(urlName == "Click to edit")
      urlName = "";
    if(urlPath == "Click to edit")
      urlPath = "";

    return "KEY=$urlKey&Name=$urlName&Path=$urlPath";
  }
}