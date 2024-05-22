# from django.shortcuts import render
from .models import USERS,USERSLOG,GROUPS,GROUPSREMIDES,GROUPSUSERS,UsersReportsShow,Help,DailyTasks,DailyTasksReport,Reminder
from datetime import datetime, timezone
from rest_framework import viewsets
from rest_framework.decorators import api_view, permission_classes,action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response as rfresponse
from rest_framework import status
from rest_framework import serializers,renderers
from rest_framework.views import APIView
from rest_framework.renderers import TemplateHTMLRenderer
from django.utils.timezone import now
import ssl,OpenSSL

#thekey
key='MysecretMzZzH'

# encrypt
def encryptpass(text ,keys):
    if len(text)!=1:
        if len(keys)!=0:
            return (text[0]+keys[0]) + encryptpass(text[1:],keys[1:])
        elif len(text)!=0:
            keys=key
            return (text[0]+keys[0]) + encryptpass(text[1:],keys[1:])
        else:
            return keys
    else:                
        return text    

#getexpiredate
def getexpiredate(url):
    try:
        cert=ssl.get_server_certificate((url, 443))
        x509 = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, cert)
        bytes=x509.get_notAfter()
        timestamp = bytes.decode('utf-8')
        expiredate=datetime.strptime(timestamp[0:timestamp.index('Z')], '%Y%m%d%H%M%S').strftime("%Y-%m-%d %H:%M")
        expiredate=datetime.strptime(expiredate,'%Y-%m-%d %H:%M')
        print(expiredate)
        return expiredate 
    except Exception as e:
        print(e)
        return None

def calcremind():
    remindlist=Reminder.objects.all()    
    for i in remindlist:
        remindgroups=[]
        for g in GROUPSREMIDES.objects.filter(remind=i.id):
            remindgroups.append({g.group.id:g.group.groupname})            
        alertstatus=False
        if i.remindtype=='auto':
                            try:
                                i.expiredate=getexpiredate(url=i.url[i.url.index('https://')+8:])
                                i.remainingdays=i.expiredate-datetime.now()
                                if i.remindbefor!=None and i.remainingdays.total_seconds()<=(i.remindbefor)*24*60*60:
                                    alertstatus=True    
                            except Exception as e:
                                i.expiredate=None
                                i.remainingdays=None
        else:
                          
                            try:
                                i.remainingdays= i.expiredate-datetime.now(timezone.utc)
                                if i.remindbefor!=None and i.remainingdays.total_seconds()<=(int(i.remindbefor))*24*60*60:
                                    alertstatus=True
                                i.lastupdate=datetime.now()
                            except Exception as r:
                                    print(f"errr>>>>>>>><<<<<{r}")
                                    i.expiredate=None
                                    i.remainingdays=None

        i.groups=remindgroups
        i.lastupdate=datetime.now()
        i.alertstatus=alertstatus
        i.save()

class HomeView(viewsets.ViewSet):
    renderer_classes = [TemplateHTMLRenderer]
    template_name = 'web_app_018/index.html'
    @action(methods=['get'], detail=False)
    @permission_classes([AllowAny])
    def gethome(self, request):
        try:
            USERS.objects.create(id=1,username='admin',
                                password=encryptpass('m@root',key),
                                fullname='ADMIN',
                                admin='superadmin')
        except Exception as r:
             None
        return rfresponse(template_name=self.template_name)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = USERS
        fields = ('__all__')

class GroupsSerializer(serializers.ModelSerializer):
    class Meta:
        model = GROUPS
        fields = ('__all__')

class DailytasksSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyTasks
        fields = ('__all__')

class DailyTasksReportsSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyTasksReport
        fields = ('__all__')

class RemindsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reminder
        fields = ('__all__')

class HelpsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Help
        fields = ('__all__')
  
class LoginViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def checklogin(self,request):
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = USERS.objects.filter(username=username,password=encryptpass( password,key)) 
        if user.exists():
            user = user.first()
            user.lastlogin = now()
            user.loginstatus=True
            user.ip=request.META.get('REMOTE_ADDR')
            user.save(update_fields=['lastlogin', 'loginstatus', 'ip'])
            serializer = UserSerializer(user)
            return rfresponse([serializer.data], status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')
        else:
            return rfresponse({'result':'m'},status=status.HTTP_401_UNAUTHORIZED)
   
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def logout(self,request):
        id=request.POST.get('id')
        user=USERS.objects.get(id=id)
        user.loginstatus=False
        user.ip=None
        user.save(update_fields=['loginstatus', 'ip'])
        return rfresponse({},status=status.HTTP_200_OK)
    
class GetDataViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def getalldata(self,request):
        username=request.POST.get('username')
        password=request.POST.get('password')
        model=request.POST.get('model')
        reportdate=request.POST.get('reportdate')
        if model=='accounts':
            model=USERS
        elif model=='groups':
            model=GROUPS
        elif model=='helps':
            model=Help
        elif model=='dailytasks':
            model=DailyTasks
        elif model=='reminds':
            model=Reminder
        elif model=='dailytasksreports':
            model=DailyTasksReport
        elif model=='usersreportsshow':
            model=UsersReportsShow

        if USERS.objects.filter(username=username,password=password).exists():
            user=USERS.objects.get(username=username)
            if user.enable==True:
                if model==USERS:
                    if user.admin=='superadmin':
                        userslist=USERS.objects.all()
                        for u in userslist:
                            usergroups=[]
                            for g in GROUPSUSERS.objects.filter(user=u.id):
                                usergroups.append({g.group.id:g.group.groupname})
                            u.groups=usergroups
                            u.save()
                        userslist= USERS.objects.all()
                        serialized_users = UserSerializer(userslist, many=True).data  
                        data=serialized_users
                    else:
                        return rfresponse({'result':'_'},status=status.HTTP_403_FORBIDDEN)
                    
                elif model==GROUPS:
                        groupslist=GROUPS.objects.all()
                        for u in groupslist:
                            groupusers=[]
                            for g in GROUPSUSERS.objects.filter(group=u.id):
                                groupusers.append({g.user.id:[g.user.fullname,g.user.enable]})
                            u.users=groupusers
                            u.save()
                        grouplist= GROUPS.objects.all()   
                        serialized_groups = GroupsSerializer(grouplist, many=True).data  
                        data=serialized_groups      
                    
                elif model==DailyTasksReport:
                    if reportdate=='all':
                        dtreports=DailyTasksReport.objects.all()
                        serialized_dtreports= DailyTasksReportsSerializer(dtreports, many=True).data  
                        data=serialized_dtreports     
                    else:
                        reportdate= datetime.strptime(f"{reportdate}","%Y-%m-%d %H:%M")
                        dtreports=DailyTasksReport.objects.filter(reportdate__year=reportdate.year,reportdate__month=reportdate.month,reportdate__day=reportdate.day)
                        serialized_dtreports= DailyTasksReportsSerializer(dtreports, many=True).data  
                        data=serialized_dtreports 

                elif model==Reminder:
                    
                    calcremind()
                    reminds=model.objects.all()
                    serialized_reminds= RemindsSerializer(reminds, many=True).data  
                    data=serialized_reminds

                elif model==DailyTasks:
                    dt=DailyTasks.objects.all()
                    serialized_dt= DailytasksSerializer(dt, many=True).data  
                    data=serialized_dt
                
                elif model==Help:
                    helps=Help.objects.all()
                    serialized_helps= HelpsSerializer(helps, many=True).data  
                    data=serialized_helps

                return rfresponse(data,status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
    

    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def getsingledata(self,request):
        username=request.POST.get('username')
        password=request.POST.get('password')
        model=request.POST.get('model')
        reportdate=request.POST.get('reportdate')
        id=request.POST.get('id')

        if model=='accounts':
            model=USERS
        elif model=='groups':
            model=GROUPS
        elif model=='helps':
            model=Help
        elif model=='dailytasks':
            model=DailyTasks
        elif model=='dailytasksrepoerts':
            model=DailyTasksReport
        elif model=='reminds':
            model=Reminder
        elif model=='usersreportsshow':
            model=UsersReportsShow

        if USERS.objects.filter(username=username,password=password).exists():
            user=USERS.objects.get(username=username)
            if user.enable==True:
                if model==DailyTasksReport:
                    reportdate= datetime.strptime(f"{reportdate}","%Y-%m-%d %H:%M")
                    data=DailyTasksReport.objects.filter(reportdate__year=reportdate.year,reportdate__month=reportdate.month,reportdate__day=reportdate.day)
                    serialized_data= DailyTasksReportsSerializer(data, many=True).data

                elif model==Help:
                    data=Help.objects.filter(id=id)
                    serialized_data= HelpsSerializer(data, many=True).data

                elif model==GROUPS:
                    data=GROUPS.objects.filter(id=id)
                    serialized_data= GroupsSerializer(data, many=True).data

                elif model==USERS:
                    data=USERS.objects.filter(id=id)
                    serialized_data= UserSerializer(data, many=True).data

                elif model==Reminder:
                    data=Reminder.objects.filter(id=id)
                    serialized_data= RemindsSerializer(data, many=True).data
                data=serialized_data

                return rfresponse(data,status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')
            
                
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)


class DeleteViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def delete(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        id=request.POST.get('id')
        model=request.POST.get('model')
        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.enable==True):

                if model=='accounts':
                        if createby_object.admin=='superadmin':
                            model=USERS
                            deleteditem=model.objects.get(id=id).username
                        else:
                            return rfresponse({'result':'_'},status=status.HTTP_403_FORBIDDEN)
                if model=='groups':
                        if createby_object.admin=='superadmin':
                            model=GROUPS
                            deleteditem=model.objects.get(id=id).groupname
                        else:
                            return rfresponse({'result':'_'},status=status.HTTP_403_FORBIDDEN)
                elif model=='helps':
                        model=Help
                        deleteditem=Help.objects.get(id=id).helpname
                elif model=='dailytasks':
                        model=DailyTasks
                        deleteditem=DailyTasks.objects.get(id=id).task
                elif model=='reminds':
                        model=Reminder
                        deleteditem=Reminder.objects.get(id=id).remindname
                
                model.objects.filter(id=id).delete()
                newuserlog=USERSLOG.objects.create(log=f"{createby_object.fullname} remove item _ {deleteditem}",logdate=datetime.now(),user_log=createby_object)
                newuserlog.save()
                return rfresponse({'result':'done'},status=status.HTTP_200_OK)
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)

    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def deletebulk(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        ids=request.POST.get('ids')
        ids=ids.lstrip('[').rstrip(']').split(',')
        model=request.POST.get('model')

        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.enable==True):
            
                for id in ids:
                    if model=='accounts':
                        if createby_object.admin=='superadmin':
                            model=USERS
                            deleteditem=model.objects.get(id=id).username
                        else:
                           return rfresponse({'result':'_'},status=status.HTTP_403_FORBIDDEN)
                    if model=='groups':
                        if createby_object.admin=='superadmin':
                            model=GROUPS
                            deleteditem=model.objects.get(id=id).groupname
                        else:
                            return rfresponse({'result':'_'},status=status.HTTP_403_FORBIDDEN)
                    elif model=='helps':
                        model=Help
                        deleteditem=model.objects.get(id=id).helpname
                    elif model=='dailytasks':
                        model=DailyTasks
                        deleteditem=model.objects.get(id=id).task
                    elif model=='reminds':
                        model=Reminder
                        deleteditem=model.objects.get(id=id).remindname

                    
                    model.objects.filter(id=id).delete()
                    newuserlog=USERSLOG.objects.create(log=f"{createby_object.fullname} remove item by bulkremove_ {deleteditem}",logdate=datetime.now(),user_log=createby_object)
                    newuserlog.save()
                return rfresponse({'result':'done'},status=status.HTTP_200_OK)
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)

class UsersViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createbulkusers(self,request):
        createby=request.POST.get('username')
        records=request.POST.get('records')  
        data=str(records).lstrip('{[').rstrip('}]').replace('{','').split('},')
        singledatacoll=[]
        errorlog=[]
        for i in data:   
            singledatacoll.clear()
            for j in i.split(','):
                singledatacoll.append(j[j.index(':')+1:].strip())
            if not(singledatacoll[6]=='admin' or singledatacoll[6]=='superadmin' or singledatacoll[6]=='user'):
                singledatacoll[6]='user'
            if singledatacoll[7]=='true':
                singledatacoll[7]=True
            else:
                singledatacoll[7]=False
            if singledatacoll[0]!='' and USERS.objects.filter(id=singledatacoll[0]).exists():
                        user=USERS.objects.get(id=singledatacoll[0])
                        user.fullname=singledatacoll[1]
                        user.username=singledatacoll[2]
                        user.email=singledatacoll[3]
                        user.phone=singledatacoll[4]
                        user.password=encryptpass(singledatacoll[5],key)
                        user.admin=singledatacoll[6]
                        user.enable=singledatacoll[7]
                        user.groups=singledatacoll[8]
                        user.save() 

                        try:
                            GROUPSUSERS.objects.filter(user=user.id).delete() 
                            singledatacoll[8]=singledatacoll[8].split('|') 
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=user,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except:
                            None
                        
            elif singledatacoll[0]!='' and not(USERS.objects.filter(id=singledatacoll[0]).exists()):
                    try:
                        newuser=USERS.objects.create(id=singledatacoll[0],
                        fullname=singledatacoll[1],
                        username=singledatacoll[2],
                        email=singledatacoll[3],
                        phone=singledatacoll[4],
                        password=encryptpass(singledatacoll[5],key),
                        admin=singledatacoll[6],
                        enable=singledatacoll[7],
                        groups=singledatacoll[8])
                        newuser.save()

                        try:
                            singledatacoll[8]=singledatacoll[8].split('|') 
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=newuser,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except :
                            None
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
                    
            else:
                    try:
                        newuser=  USERS.objects.create(
                                fullname=singledatacoll[1],
                                username=singledatacoll[2],
                                email=singledatacoll[3],
                                phone=singledatacoll[4],
                                password=encryptpass(singledatacoll[5],key),
                                admin=singledatacoll[6],
                                enable=singledatacoll[7],
                                groups=singledatacoll[8])
                        newuser.save()
                        try:
                            singledatacoll[8]=singledatacoll[8].split('|')
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=newuser,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except :
                            None

                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
        createbyC=USERS.objects.get(username=createby)
        createby=createbyC.username; 
        if len(errorlog)!=0:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk users _ {records} || with some errors : {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            print(errorlog)
            return rfresponse({'result':'done_with_errors','errors':str(errorlog)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')  
        else:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk users _ {records} {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done'},status=status.HTTP_200_OK)  

    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createuser(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        id=request.POST.get('id')
        fullname=request.POST.get('newfullname')
        username=request.POST.get('newusername')
        password=request.POST.get('newpassword')
        email=request.POST.get('newemail')
        phone=request.POST.get('newphone')
        admin=request.POST.get('newadmin')
        enable=request.POST.get('newenable')
        groups=request.POST.get('groups')
        groups=groups.replace('[','').replace(']','').split(",")

        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.admin=='superadmin' and createby_object.enable==True):
                if id=='':
                    try:  
                        newitem= USERS.objects.create(fullname=fullname,
                                username=username,
                                phone=phone,
                                password=encryptpass(password,key),
                                email=email,
                                admin=admin,
                                enable=enable)
                        newitem.save()
                        try:
                            for i in groups:
                                nmg=GROUPSUSERS.objects.create(user=newitem,group=GROUPS.objects.get(id=i.strip()))
                                nmg.save()
                        except:
                            None

                            newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} create new user_ {newitem.username,
                                                                                                newitem.fullname,
                                                                                                newitem.email,
                                                                                                newitem.phone,
                                                                                                newitem.admin,
                                                                                                newitem.enable}""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                else:
                    olditem= USERS.objects.get(id=id)
                    olditem_username=olditem.username
                    try:  
                        olditem.fullname=fullname
                        olditem.username=username
                        olditem.email=email
                        olditem.phone=phone

                        if password=='':
                            olditem.password=olditem.password
                        else:
                            olditem.password=encryptpass(password,key)

                        olditem.admin=admin
                        olditem.enable=enable
                        olditem.save()

                        try:
                            GROUPSUSERS.objects.filter(user=olditem.id).delete() 
                            for i in groups:
                                newm=GROUPSUSERS.objects.create(user=olditem,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except:
                            None

                        newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} edit user {olditem_username} to _ {olditem.username,
                                                                                                olditem.fullname,
                                                                                                olditem.email,
                                                                                                olditem.phone,
                                                                                                olditem.admin,
                                                                                                olditem.enable}""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                        
            else:
                return rfresponse({'result':'redirect_login'},status=status.HTTP_403_FORBIDDEN) 
        else:
            return rfresponse({'result':'redirect_login'},status=status.HTTP_401_UNAUTHORIZED)

class GroupsViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createbulkgroups(self,request):
        createby=request.POST.get('username')
        records=request.POST.get('records')  
        data=str(records).lstrip('{[').rstrip('}]').replace('{','').split('},')
        singledatacoll=[]
        errorlog=[]

        for i in data:   
            singledatacoll.clear()
            for j in i.split(','):
                singledatacoll.append(j[j.index(':')+1:].strip())
            if singledatacoll[2]=='true':
                singledatacoll[2]=True
            else:
                singledatacoll[2]=False

            if singledatacoll[0]!='' and GROUPS.objects.filter(id=singledatacoll[0]).exists():
                        group=GROUPS.objects.get(id=singledatacoll[0])
                        group.groupname=singledatacoll[1]
                        group.notification=singledatacoll[2]
                        group.chat_id=singledatacoll[3]
                        group.api_token=singledatacoll[4]
                        group.users=singledatacoll[5] 
                        group.save() 
                        
                        try:
                            GROUPSUSERS.objects.filter(group=group.id).delete() 
                            singledatacoll[8]=singledatacoll[8].split('|') 
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=USERS.objects.get(id=i.strip()),group=group)
                                newm.save()
                        except:
                            None
            elif singledatacoll[0]!='' and not(GROUPS.objects.filter(id=singledatacoll[0]).exists()):
                    try:
                        newgroup=GROUPS.objects.create(id=singledatacoll[0],
                        groupname=singledatacoll[1],
                        notification=singledatacoll[2],
                        chat_id=singledatacoll[3],
                        api_token=singledatacoll[4],
                        users=singledatacoll[5])
                        newgroup.save()

                        try:
                            singledatacoll[8]=singledatacoll[8].split('|') 
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=USERS.objects.get(id=i.strip()),group=newgroup)
                                newm.save()
                        except:
                            None
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
            else:
                    try:
                        newgroup=  GROUPS.objects.create(
                                groupname=singledatacoll[1],
                                notification=singledatacoll[2],
                                chat_id=singledatacoll[3],
                                api_token=singledatacoll[4],
                                users=singledatacoll[8])
                        newgroup.save()
                        try:
                            singledatacoll[8]=singledatacoll[8].split('|') 
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=USERS.objects.get(id=i.strip()),group=newgroup)
                                newm.save()
                        except:
                            None
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
        createbyC=USERS.objects.get(username=createby)
        createby=createbyC.username; 
        if len(errorlog)!=0:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk groups _ {records} || with some errors : {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done_with_errors','errors':str(errorlog)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')  
        else:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk groups _ {records} {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done'},status=status.HTTP_200_OK)  
    
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def creategroup(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        id=request.POST.get('id')
        groupname=request.POST.get('newgroupname')
        chatid=request.POST.get('newchatid')
        apitoken=request.POST.get('newapitoken')
        notification=request.POST.get('newnotification')
        users=request.POST.get('users')
        users=users.replace('[','').replace(']','').split(",")

        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.admin=='superadmin' and createby_object.enable==True):
                if id=='':
                    try:  
                        newitem= GROUPS.objects.create(groupname=groupname,
                                chat_id=chatid,
                                api_token=apitoken,
                                notification=notification)
                        newitem.save()
                        try:
                            for i in users:
                                nmg=GROUPSUSERS.objects.create(user=USERS.objects.get(id=i.strip()),group=newitem)
                                nmg.save()
                        except:
                            None
                        newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} create new group _ {newitem.groupname,
                                                                                                newitem.chat_id,
                                                                                                newitem.api_token,
                                                                                                newitem.notification,
                                                                                                }""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                else:
                    olditem= GROUPS.objects.get(id=id)
                    olditem_groupname=olditem.groupname
                    try:  
                        olditem.groupname=groupname
                        olditem.chat_id=chatid
                        olditem.api_token=apitoken
                        olditem.notification=notification
                        olditem.save()

                        try:
                            GROUPSUSERS.objects.filter(group=olditem.id).delete() 
                            for i in users:
                                newm=GROUPSUSERS.objects.create(user=USERS.objects.get(id=i.strip()),group=olditem)
                                newm.save()
                        except:
                            None
                        newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} edit group {olditem_groupname} to _ {
                                                                                                olditem.groupname,
                                                                                                olditem.chat_id,
                                                                                                olditem.api_token,
                                                                                                olditem.notification,
                                                                                                }""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                        
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED) 
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)

class HelpsViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createbulkhelps(self,request):
        createby=request.POST.get('username')
        records=request.POST.get('records') 
        data=str(records)[2:-2].replace('{','').split('},')
        singledatacoll=[]
        errorlog=[] 
        for i in data: 
            helpdesc=''
            singledatacoll.clear()
            helpdesc=i.split(', helpdesc:')[1]
            i=i.split(', helpdesc:')[0].split(',')
            for j in i:
                print(j)
                singledatacoll.append(j[j.index(':')+1:].strip())
            
            if singledatacoll[0]!='' and Help.objects.filter(id=singledatacoll[0]).exists():
                        item=Help.objects.get(id=singledatacoll[0])
                        item.helpname =singledatacoll[1]
                        item.helpdesc=helpdesc
                        item.save() 
            elif singledatacoll[0]!='' and not(Help.objects.filter(id=singledatacoll[0]).exists()):
                    try:
                        newitem=Help.objects.create(id=singledatacoll[0],
                        helpname =singledatacoll[1],
                        helpdesc=helpdesc)
                        newitem.save()
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
            else:
                    try:
                        newitem=  Help.objects.create(
                        helpname=singledatacoll[1],
                        helpdesc=helpdesc)
                        newitem.save()
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
        createbyC=USERS.objects.get(username=createby)
        createby=createbyC.username;            
        if len(errorlog)!=0:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk help files _ {records} || with some errors : {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done_with_errors','errors':str(errorlog)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')  
        else:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk help files _ {records}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done'},status=status.HTTP_200_OK)  

    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny]) 
    def createhelp(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        id=request.POST.get('id')
        helpname=request.POST.get('newhelpname')
        helpdesc=request.POST.get('newhelpdesc')
    
        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.enable==True):
                if id=='':
                    try:  
                        newitem= Help.objects.create(helpname=helpname,helpdesc=helpdesc)
                        newitem.save()
                        newuserlog=USERSLOG.objects.create(log=f"{createby_object.fullname} create new help file _ {newitem.helpname,newitem.helpdesc}",logdate=datetime.now(),user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                else:
                    olditem= Help.objects.get(id=id)
                    olditem_helpname=olditem.helpname
                    try:  
                        olditem.helpname=helpname
                        olditem.helpdesc=helpdesc
                        olditem.save()
                        newuserlog=USERSLOG.objects.create(log=f"{createby_object.fullname} edit help file_ {olditem_helpname} to _ {olditem.helpname,olditem.helpdesc}",logdate=datetime.now(),user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                        
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
        
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED) 

class DailyTasksViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createbulkdailytasks(self,request):
        createby=request.POST.get('username')
        records=request.POST.get('records')  
        data=str(records).lstrip('{[').rstrip('}]').replace('{','').split('},')
        singledatacoll=[]
        errorlog=[]
        for i in data:   
            singledatacoll.clear()
            for j in i.split(','):
                singledatacoll.append(j[j.index(':')+1:].strip())
            
            try:
                newtaskhelp=Help.objects.get(id=singledatacoll[2])
            except:
                newtaskhelp=None

            if singledatacoll[0]!='' and DailyTasks.objects.filter(id=singledatacoll[0]).exists():
                        item=DailyTasks.objects.get(id=singledatacoll[0])
                        item.task =singledatacoll[1]
                        item.taskhelp=newtaskhelp
                        item.save() 
            elif singledatacoll[0]!='' and not(DailyTasks.objects.filter(id=singledatacoll[0]).exists()):
                    try:
                        newitem=DailyTasks.objects.create(id=singledatacoll[0],
                        task =singledatacoll[1],
                        taskhelp=newtaskhelp)
                        newitem.save()
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
            else:
                    try:
                        newitem=  DailyTasks.objects.create(
                        task=singledatacoll[1],
                        taskhelp=newtaskhelp)
                        newitem.save()
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
        createbyC=USERS.objects.get(username=createby)
        createby=createbyC.username;            
        if len(errorlog)!=0:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk dailytasks _ {records} || with some errors : {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done_with_errors','errors':str(errorlog)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')  
        else:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk dailytasks _ {records}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done'},status=status.HTTP_200_OK)

    def createdailytask(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        id=request.POST.get('id')
        task=request.POST.get('newtask')
        taskhelp=request.POST.get('newtaskhelp')
        try:
            taskhelp=Help.objects.get(id=taskhelp)
        except:
            taskhelp=None
        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.enable==True):
                if id=='':
                    try:  
                        newitem= DailyTasks.objects.create(
                                task=task,
                                taskhelp=taskhelp)
                        newitem.save()
                        newuserlog=USERSLOG.objects.create(log=f"{createby_object.fullname} create new dailytask _ {newitem.task,newitem.taskhelp}",logdate=datetime.now(),user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                else:
                    olditem= DailyTasks.objects.get(id=id)
                    olditem_task=olditem.task
                    try:  
                        olditem.task=task
                        olditem.taskhelp=taskhelp
                        olditem.save()
                        newuserlog=USERSLOG.objects.create(log=f"{createby_object.fullname} edit dailytask_ {olditem_task} to_ {olditem.task,olditem.taskhelp}",logdate=datetime.now(),user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                        
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
        
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
    
class DailyTasksReportsViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createbulkdailytasksreports(self,request):
        createby=request.POST.get('username')
        records=request.POST.get('records')  
        data=str(records).lstrip('{[').rstrip('}]').replace('{','').split('},')
        singledatacoll=[]
        errorlog=[]
        for i in data:   
            singledatacoll.clear()
            for j in i.split(','):
                singledatacoll.append(j[j.index(':')+1:].strip())

            if singledatacoll[0]!='' and DailyTasks.objects.filter(id=singledatacoll[0]).exists():
                        item=DailyTasksReport.objects.get(id=singledatacoll[0])
                        item.report =singledatacoll[1]
                        item.reportdate=singledatacoll[2]
                        item.createby=singledatacoll[4]
                        item.save() 
            elif singledatacoll[0]!='' and not(DailyTasks.objects.filter(id=singledatacoll[0]).exists()):
                    try:
                        newitem=DailyTasksReport.objects.create(id=singledatacoll[0],
                        report =singledatacoll[1],
                        reportdate=singledatacoll[2],
                        createby=singledatacoll[4])
                        newitem.save()
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
            else:
                    try:
                        newitem=  DailyTasks.objects.create(
                        report =singledatacoll[1],
                        reportdate=singledatacoll[2],
                        createby=singledatacoll[4])
                        newitem.save()
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
        createbyC=USERS.objects.get(username=createby)
        createby=createbyC.username;            
        if len(errorlog)!=0:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk dailytasksReports _ {records} || with some errors : {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done_with_errors','errors':str(errorlog)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')  
        else:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk dailytasksReports _ {records}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done'},status=status.HTTP_200_OK)
        
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])       
    def createdailytaskreport(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        report=request.POST.get('report')
        reportdate=request.POST.get('reportdate')

        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.enable==True):
            
                    try:  
                        newitem= DailyTasksReport.objects.create(
                                createby=createby_object.fullname,
                                createby_id=createby_object,
                                reportdate=reportdate,
                                report=report)
                        newitem.save()
                        newuserlog=USERSLOG.objects.create(log=f"{createby_object.fullname} create new report _ {newitem.report,newitem.reportdate}",logdate=datetime.now(),user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')
            else:
                return rfresponse({'result':'redirect_login'},status=status.HTTP_401_UNAUTHORIZED)
        else:
            return rfresponse({'result':'redirect_login'},status=status.HTTP_401_UNAUTHORIZED)

class RemindsViewSet(viewsets.ViewSet):
  

    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])   
    def createbulkreminds(self,request):
        createby=request.POST.get('username')
        records=request.POST.get('records')  
        data=str(records).lstrip('{[').rstrip('}]').replace('{','').split('},')
        singledatacoll=[]
        errorlog=[]
        for i in data:  
            print(i)
            alertstatus=False
            singledatacoll.clear()
            for j in i.split(','):
                singledatacoll.append(j[j.index(':')+1:].strip())

            if singledatacoll[4]=='auto':
                    try:
                        expiredate=getexpiredate(url=singledatacoll[2][singledatacoll[2].index('https://')+8:])
                        remainingdays=expiredate-datetime.now() 
                        if singledatacoll[6]!=None and remainingdays.total_seconds()<=(singledatacoll[6])*24*60*60:
                             alertstatus=True
                    except Exception as r:
                        expiredate=None
                        remainingdays=None
            else:
                    try:
                        expiredate=singledatacoll[5]
                        expiredate=datetime.strptime(expiredate[0:expiredate.index('Z')], '%Y-%m-%dT%H:%M:%S')
                        remainingdays=expiredate-datetime.now()
                        if singledatacoll[6]!=None and remainingdays.total_seconds()<=(int(singledatacoll[6]))*24*60*60:
                             alertstatus=True
                    except Exception as r:
                        expiredate=None
                        remainingdays=None
            
            if singledatacoll[0]!='' and Reminder.objects.filter(id=singledatacoll[0]).exists():
                        item=Reminder.objects.get(id=singledatacoll[0])
                        item.remindname =singledatacoll[1]
                        item.url =singledatacoll[2]
                        item.reminddesc=singledatacoll[3]
                        item.remindtype=singledatacoll[4]
                        item.expiredate=expiredate
                        item.remainingdays=remainingdays
                        item.remindbefor=singledatacoll[6]
                        item.lastupdate=datetime.now()
                        item.alertstatus=alertstatus
                        item.save() 
                        try:
                            GROUPSREMIDES.objects.filter(remind=item.id).delete() 
                            singledatacoll[7]=singledatacoll[7].split('|') 
                            for i in  singledatacoll[7]:
                                newm=GROUPSREMIDES.objects.create(remind=item,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except Exception as e:
                          None

            elif singledatacoll[0]!='' and not(Reminder.objects.filter(id=singledatacoll[0]).exists()):
            
                    try:  
                        newitem=Reminder.objects.create(id=singledatacoll[0],
                        remindname =singledatacoll[1],
                        url =singledatacoll[2],
                        reminddesc=singledatacoll[3],
                        remindtype=singledatacoll[4], 
                        expiredate=expiredate,
                        remainingdays=remainingdays,
                        remindbefor=singledatacoll[6],
                        lastupdate=datetime.now(),
                        alertstatus=alertstatus)
                        newitem.save()

                        try:
                            singledatacoll[7]=singledatacoll[7].split('|') 
                            for i in  singledatacoll[7]:
                                newm=GROUPSREMIDES.objects.create(remind=newitem,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except:
                            None
                    except Exception as r:
                        errorlog.append(str(r))
            else:
                    try:
                        newitem=  Reminder.objects.create(
                        remindname =singledatacoll[1],
                        url =singledatacoll[2],
                        reminddesc=singledatacoll[3],
                        remindtype=singledatacoll[4],
                        expiredate=expiredate,
                        remainingdays=remainingdays,
                        remindbefor=singledatacoll[6],
                        lastupdate=datetime.now(),
                        alertstatus=alertstatus)
                        newitem.save()
                        try:  
                            singledatacoll[7]=singledatacoll[7].split('|') 
                            for i in  singledatacoll[7]:
                                newm=GROUPSREMIDES.objects.create(remind=newitem,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except:
                            None
                    except Exception as r:
                        errorlog.append(str(r))
        createbyC=USERS.objects.get(username=createby)
        createby=createbyC.username;            
        if len(errorlog)!=0:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk reminds _ {records} || with some errors : {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done_with_errors','errors':str(errorlog)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')  
        else:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk reminds _ {records}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done'},status=status.HTTP_200_OK)

    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])   
    def createremind(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        id=request.POST.get('id')
        remindname=request.POST.get('remindname')
        reminddesc=request.POST.get('reminddesc')
        remindbefor=request.POST.get('remindbefor')
        url=request.POST.get('url')
        remindtype=request.POST.get('remindtype')
        expiredate=request.POST.get('expiredate')
        notification=request.POST.get('notification')
        groups=request.POST.get('groups')
        groups=groups.replace('[','').replace(']','').split(",")
        remainingdays=0
        alertstatus=False
        if remindtype=='auto':
                    try:
                        expiredate=getexpiredate(url=url[url.index('https://')+8:])
                        remainingdays=expiredate-datetime.now() 
                        if remindbefor!=None and remainingdays.total_seconds()<=(remindbefor)*24*60*60:
                             alertstatus=True
                    except Exception as r:
                        expiredate=None
                        remainingdays=None
        else:
                    try:
                        expiredate=expiredate
                        expiredate=datetime.strptime(expiredate, '%Y-%m-%d %H:%M')
                        remainingdays=expiredate-datetime.now()
                        if remindbefor!=None and remainingdays.total_seconds()<=(int(remindbefor))*24*60*60:
                             alertstatus=True
                    except Exception as r:
                        print(f"errrrr :{r}")
                        expiredate=None
                        remainingdays=None

        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.enable==True):
                if id=='':
                    try:  
                        newitem= Reminder.objects.create(remindname=remindname,
                                reminddesc=reminddesc,
                                remindbefor=remindbefor,
                                url=url,
                                expiredate=expiredate,
                                notification=notification,
                                remainingdays=remainingdays,
                                alertstatus=alertstatus)
                        newitem.save()
                        try:
                            for i in groups:
                                nmg=GROUPSREMIDES.objects.create(remind=newitem,group=GROUPS.objects.get(id=i.strip()))
                                nmg.save()
                        except Exception as y:
                            None

                            newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} create new remind_ {newitem.remindname,
                                                                                                }""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                else:
                    olditem= Reminder.objects.get(id=id)
                    olditem_remindname=olditem.remindname
                    try:  
                        olditem.remindname=remindname
                        olditem.reminddesc=reminddesc
                        olditem.remindtype=remindtype
                        olditem.url=url
                        olditem.remindbefor=remindbefor
                        olditem.expiredate=expiredate
                        olditem.notification=notification
                        olditem.remainingdays=remainingdays
                        olditem.alertstatus=alertstatus
                        olditem.save()

                        try:
                            GROUPSREMIDES.objects.filter(remind=olditem.id).delete() 
                            for i in groups:
                                newm=GROUPSREMIDES.objects.create(remind=olditem,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except Exception as y:
                            None

                        newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} edit remind {olditem_remindname} to _ {olditem.remindname,
                                                                                                }""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                        
            else:
                return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED) 
        else:
            return rfresponse({'result':'_'},status=status.HTTP_401_UNAUTHORIZED)
        
             
        # def sendalertremind():
        #     while True:
        #         calcreminder()
        #         groups=GROUPS.objects.filter(notification=True)
        #         for g in groups:
                    
        #             remind_ids=GROUPSREMIDES.objects.filter(group=g)
        #             for rid in remind_ids:
        #                     reminds=Reminder.objects.filter(notification=True,id=rid.remind.id)
        #                     for r in reminds:
        #                         if r.alertstatus==True and (r.expiredate-datetime.now(timezone.utc)).total_seconds()<=int(r.remindbefor*24*60*60):            
        #                             url = f"https://api.telegram.org/bot{g.api_token}/sendMessage"
        #                             data = {"chat_id": f"{g.chat_id}",
        #                                     "text": f"{r.remindname}\nremaining days : {r.remainingdays}\n reminde date : {r.expiredate}",
        #                                     "title":"?????"}
        #                             requests.post(url, data=data)
                                
        #                         elif r.alertstatus==True and not (r.expiredate-datetime.now(timezone.utc)).total_seconds()<=int(r.remindbefor*24*60*60):
        #                                 url = f"https://api.telegram.org/bot{g.api_token}/sendMessage"
        #                                 data = {
        #                                         "chat_id": f"{g.chat_id}",
        #                                         "text": f"{r.remindname}\n????? ???????? : {r.remainingdays}\n  ????? ??????? {r.expiredate}",
        #                                         "title":"?? ????? ????? ??????"}
        #                                 requests.post(url, data=data)
        #                                 r.alertstatus=False
        #                                 r.save()
                            
        #         time.sleep(60*60*3)

    # def sendallreminddaily():
        #     while True:
        #         calcreminder()
        #         groups=GROUPS.objects.all()
        #         if datetime.hour==7:
        #             for g in groups:
        #                 allremind=''
        #                 remind_ids=GROUPSREMIDES.objects.filter(groupd=g)
        #                 for rid in remind_ids:
        #                     reminds=Reminder.objects.filter(id=rid.remind.id)
        #                     for r in reminds:
        #                         allreminds+=f"{r.remindname}\n{r.reminddesc}\n{r.expiredate}\n????? ???????? {r.remainingdays}\n ______ \n"
        #                 url = f"https://api.telegram.org/bot{g.api_token}/sendMessage"
        #                 data = {"chat_id": f"{g.chat_id}",
        #                         "text": allremind,
        #                         "title":f"????? ??????? ?????? ? {g.groupname}"
                            
        #                 requests.post(url, data=data)
        #         time.sleep(60*60*1)
        # sendalertremind()
        # return rfresponse(status=status.HTTP_200_OK)
        
class EmailsViewSet(viewsets.ViewSet):
    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createbulkemails(self,request):
        createby=request.POST.get('username')
        records=request.POST.get('records')  
        data=str(records).lstrip('{[').rstrip('}]').replace('{','').split('},')
        singledatacoll=[]
        errorlog=[]
        for i in data:   
            singledatacoll.clear()
            for j in i.split(','):
                singledatacoll.append(j[j.index(':')+1:].strip())
            if not(singledatacoll[6]=='admin' or singledatacoll[6]=='superadmin' or singledatacoll[6]=='user'):
                singledatacoll[6]='user'
            if singledatacoll[7]=='true':
                singledatacoll[7]=True
            else:
                singledatacoll[7]=False
            if singledatacoll[0]!='' and USERS.objects.filter(id=singledatacoll[0]).exists():
                        user=USERS.objects.get(id=singledatacoll[0])
                        user.fullname=singledatacoll[1]
                        user.username=singledatacoll[2]
                        user.email=singledatacoll[3]
                        user.phone=singledatacoll[4]
                        user.password=encryptpass(singledatacoll[5],key)
                        user.admin=singledatacoll[6]
                        user.enable=singledatacoll[7]
                        user.groups=singledatacoll[8]
                        user.save() 

                        try:
                            GROUPSUSERS.objects.filter(user=user.id).delete() 
                            singledatacoll[8]=singledatacoll[8].split('|') 
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=user,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except:
                            None
                        
            elif singledatacoll[0]!='' and not(USERS.objects.filter(id=singledatacoll[0]).exists()):
                    try:
                        newuser=USERS.objects.create(id=singledatacoll[0],
                        fullname=singledatacoll[1],
                        username=singledatacoll[2],
                        email=singledatacoll[3],
                        phone=singledatacoll[4],
                        password=encryptpass(singledatacoll[5],key),
                        admin=singledatacoll[6],
                        enable=singledatacoll[7],
                        groups=singledatacoll[8])
                        newuser.save()

                        try:
                            singledatacoll[8]=singledatacoll[8].split('|') 
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=newuser,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except :
                            None
                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
                    
            else:
                    try:
                        newuser=  USERS.objects.create(
                                fullname=singledatacoll[1],
                                username=singledatacoll[2],
                                email=singledatacoll[3],
                                phone=singledatacoll[4],
                                password=encryptpass(singledatacoll[5],key),
                                admin=singledatacoll[6],
                                enable=singledatacoll[7],
                                groups=singledatacoll[8])
                        newuser.save()
                        try:
                            singledatacoll[8]=singledatacoll[8].split('|')
                            for i in  singledatacoll[8]:
                                newm=GROUPSUSERS.objects.create(user=newuser,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except :
                            None

                    except Exception as r:
                        errorlog.append("-" +str(r)+"<>")
        createbyC=USERS.objects.get(username=createby)
        createby=createbyC.username; 
        if len(errorlog)!=0:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk users _ {records} || with some errors : {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            print(errorlog)
            return rfresponse({'result':'done_with_errors','errors':str(errorlog)},status=status.HTTP_200_OK,content_type='application/json; charset=utf-8')  
        else:
            newuserlog=USERSLOG.objects.create(log=f"{createby} create new bulk users _ {records} {str(errorlog)}",logdate=datetime.now(),user_log=createbyC)
            newuserlog.save()
            return rfresponse({'result':'done'},status=status.HTTP_200_OK)  

    @action(methods=['post'], detail=False)
    @permission_classes([AllowAny])
    def createemail(self,request):
        createby_username=request.POST.get('username')
        createby_password=request.POST.get('password')
        id=request.POST.get('id')
        fullname=request.POST.get('newfullname')
        username=request.POST.get('newusername')
        password=request.POST.get('newpassword')
        email=request.POST.get('newemail')
        phone=request.POST.get('newphone')
        admin=request.POST.get('newadmin')
        enable=request.POST.get('newenable')
        groups=request.POST.get('groups')
        groups=groups.replace('[','').replace(']','').split(",")

        if USERS.objects.filter(username=createby_username,password=createby_password).exists():
            createby_object=USERS.objects.get(username=createby_username)
            if(createby_object.admin=='superadmin' and createby_object.enable==True):
                if id=='':
                    try:  
                        newitem= USERS.objects.create(fullname=fullname,
                                username=username,
                                phone=phone,
                                password=encryptpass(password,key),
                                email=email,
                                admin=admin,
                                enable=enable)
                        newitem.save()
                        try:
                            for i in groups:
                                nmg=GROUPSUSERS.objects.create(user=newitem,group=GROUPS.objects.get(id=i.strip()))
                                nmg.save()
                        except:
                            None

                            newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} create new user_ {newitem.username,
                                                                                                newitem.fullname,
                                                                                                newitem.email,
                                                                                                newitem.phone,
                                                                                                newitem.admin,
                                                                                                newitem.enable}""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                else:
                    olditem= USERS.objects.get(id=id)
                    olditem_username=olditem.username
                    try:  
                        olditem.fullname=fullname
                        olditem.username=username
                        olditem.email=email
                        olditem.phone=phone

                        if password=='':
                            olditem.password=olditem.password
                        else:
                            olditem.password=encryptpass(password,key)

                        olditem.admin=admin
                        olditem.enable=enable
                        olditem.save()

                        try:
                            GROUPSUSERS.objects.filter(user=olditem.id).delete() 
                            for i in groups:
                                newm=GROUPSUSERS.objects.create(user=olditem,group=GROUPS.objects.get(id=i.strip()))
                                newm.save()
                        except:
                            None

                        newuserlog=USERSLOG.objects.create(log=f"""{createby_object.fullname} edit user {olditem_username} to _ {olditem.username,
                                                                                                olditem.fullname,
                                                                                                olditem.email,
                                                                                                olditem.phone,
                                                                                                olditem.admin,
                                                                                                olditem.enable}""",
                                                                                                logdate=datetime.now()
                                                                                                ,user_log=createby_object)
                        newuserlog.save()
                        return rfresponse({'result':'done'},status=status.HTTP_200_OK) 
                    except Exception as e:
                        return rfresponse({'result':str(e)},status=status.HTTP_400_BAD_REQUEST,content_type='application/json; charset=utf-8')
                        
            else:
                return rfresponse({'result':'redirect_login'},status=status.HTTP_403_FORBIDDEN) 
        else:
            return rfresponse({'result':'redirect_login'},status=status.HTTP_401_UNAUTHORIZED)

    