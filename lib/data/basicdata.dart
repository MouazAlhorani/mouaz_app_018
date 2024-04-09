class BasicData {
  static List? userinfo;
  static int r = 0;

  static String startdate = "2024-02-01";
  static String enddate = "2025-01-01";

  // static String baseurl = "http://127.0.0.1:80/";
  static String baseurl = "http://192.168.30.20:80/";

  static String checklogin = "api/login/";
  static String logout = "api/logout/";

  static String getalldata = "api/getalldata/";
  static String getsingledata = "api/getsingledata/";

  static String delete = "api/delete/";
  static String deletebulk = "api/deletebulk/";

  static String createuser = "api/users/createuser/";
  static String createbulkusers = "api/users/createbulkusers/";

  static String creategroup = "api/groups/creategroup/";
  static String createbulkgroups = "api/groups/createbulkgroups/";

  static String createhelp = "api/helps/createhelp/";
  static String createbulkhelps = "api/helps/createbulkhelps/";

  static String createtask = "api/dailytasks/createdailytask/";
  static String createbulktasks = "api/dailytasks/createbulkdailytasks/";

  static String createdailytaskreport =
      "api/dailytasksreports/createdailytaskreport/";
  static String createbulkdailytasksreports =
      "api/dailytasksreports/createbulkdailytasksreports/";

  static String createemailelement = "api/dailytasks/createemailelement/";

  static String telegram = "api/reminds/remindfromtogather/";
  static String createremind = "api/reminds/createremind/";
  static String createbulkreminds = "api/reminds/createbulkreminds/";

  static String createusershowreport = "createusershowreport/";
}
