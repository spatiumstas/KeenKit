import os #line:1
import random #line:2
import string #line:3
import sys #line:4
import re #line:5
import zlib #line:6
def generate_random_string (OO00OO00000O00O0O ,O000O0O00O0OOOO00 ):#line:8
    return ''.join (random .choice (O000O0O00O0OOOO00 )for _OO0O000O0O000O0O0 in range (OO00OO00000O00O0O ))#line:9
def replace_field (O0000OO0000O00OOO ,O0O0O0O0000O00OO0 ,O00O0OOOO0000O0OO ):#line:11
    OOOOOOOOOOOOO00OO =O0000OO0000O00OOO .find (O0O0O0O0000O00OO0 )#line:12
    if OOOOOOOOOOOOO00OO !=-1 :#line:13
        OOO00000O0OOOO0O0 =OOOOOOOOOOOOO00OO +len (O0O0O0O0000O00OO0 )#line:14
        O0000OO0O00OOOO0O =O0000OO0000O00OOO .find (b'\x00',OOO00000O0OOOO0O0 )#line:15
        if O0000OO0O00OOOO0O !=-1 :#line:16
            O0000OO0000O00OOO =O0000OO0000O00OOO [:OOO00000O0OOOO0O0 ]+O00O0OOOO0000O0OO +O0000OO0000O00OOO [OOO00000O0OOOO0O0 +len (O00O0OOOO0000O0OO ):O0000OO0O00OOOO0O ]+O0000OO0000O00OOO [O0000OO0O00OOOO0O :]#line:17
            return O0000OO0000O00OOO ,True #line:18
    return O0000OO0000O00OOO ,False #line:19
def replace_server (OO0O000O0O0OO0OOO ):#line:21
    O0OO000OOO0000O00 =b'keenetic.net\x00'#line:22
    O0O0OOOO0O0O000O0 =OO0O000O0O0OO0OOO .find (O0OO000OOO0000O00 )#line:23
    if O0O0OOOO0O0O000O0 !=-1 :#line:25
        O00O0OOO0OO00O0OO =b'keenetic.ru\x00'#line:26
        OO0O000O0O0OO0OOO =OO0O000O0O0OO0OOO [:O0O0OOOO0O0O000O0 ]+O00O0OOO0OO00O0OO +OO0O000O0O0OO0OOO [O0O0OOOO0O0O000O0 +len (O0OO000OOO0000O00 ):]#line:27
        O0000O0O00O00O0OO =-1 #line:29
        for OO0O0O000O0O000O0 in range (O0O0OOOO0O0O000O0 +len (O00O0OOO0OO00O0OO ),len (OO0O000O0O0OO0OOO )):#line:30
            if OO0O000O0O0OO0OOO [OO0O0O000O0O000O0 ]==0xFF :#line:31
                O0000O0O00O00O0OO =OO0O0O000O0O000O0 #line:32
                break #line:33
        if O0000O0O00O00O0OO !=-1 :#line:35
            OO0O000O0O0OO0OOO =OO0O000O0O0OO0OOO [:O0000O0O00O00O0OO ]+b'\x00'+OO0O000O0O0OO0OOO [O0000O0O00O00O0OO :]#line:36
        return OO0O000O0O0OO0OOO ,True ,'net_to_ru'#line:38
    else :#line:39
        OOO000000OO000O0O =b'keenetic.ru\x00'#line:40
        O0O0OOOO0O0O000O0 =OO0O000O0O0OO0OOO .find (OOO000000OO000O0O )#line:41
        if O0O0OOOO0O0O000O0 !=-1 :#line:42
            O00O0OOO0OO00O0OO =b'keenetic.net\x00'#line:43
            OO0O000O0O0OO0OOO =OO0O000O0O0OO0OOO [:O0O0OOOO0O0O000O0 ]+O00O0OOO0OO00O0OO +OO0O000O0O0OO0OOO [O0O0OOOO0O0O000O0 +len (OOO000000OO000O0O ):]#line:44
            O0000O0O00O00O0OO =-1 #line:46
            for OO0O0O000O0O000O0 in range (O0O0OOOO0O0O000O0 +len (O00O0OOO0OO00O0OO ),len (OO0O000O0O0OO0OOO )):#line:47
                if OO0O000O0O0OO0OOO [OO0O0O000O0O000O0 ]==0xFF :#line:48
                    O0000O0O00O00O0OO =OO0O0O000O0O000O0 #line:49
                    break #line:50
            if O0000O0O00O00O0OO !=-1 :#line:52
                OO0O000O0O0OO0OOO =OO0O000O0O0OO0OOO [:O0000O0O00O00O0OO -1 ]+OO0O000O0O0OO0OOO [O0000O0O00O00O0OO :]#line:53
            return OO0O000O0O0OO0OOO ,True ,'ru_to_net'#line:55
        else :#line:56
            return OO0O000O0O0OO0OOO ,False ,'not_found'#line:57
def check (O0OO000O0000OO000 ):#line:59
    O00O00OO0OOOOO0OO =4 #line:60
    OO0O000OOO00O00O0 =len (O0OO000O0000OO000 )#line:61
    for O00OOO000OOOOO0O0 in range (O00O00OO0OOOOO0OO ,len (O0OO000O0000OO000 )):#line:62
        if O0OO000O0000OO000 [O00OOO000OOOOO0O0 ]==0xFF :#line:63
            OO0O000OOO00O00O0 =O00OOO000OOOOO0O0 #line:64
            break #line:65
    OOOO00O00OOOO0000 =O0OO000O0000OO000 [O00O00OO0OOOOO0OO :OO0O000OOO00O00O0 ]#line:66
    OOOO00O0OOO0O0000 =zlib .crc32 (OOOO00O00OOOO0000 )&0xFFFFFFFF #line:67
    O0OO000O0000OO000 =OOOO00O0OOO0O0000 .to_bytes (4 ,byteorder ='little')+O0OO000O0000OO000 [4 :]#line:68
    return O0OO000O0000OO000 ,OOOO00O0OOO0O0000 #line:69
def verify (OO00OOOOOOO0O0O0O ):#line:71
    with open (OO00OOOOOOO0O0O0O ,'rb')as OOO0O0O0OO00O0OOO :#line:72
        OOO000O00O00OOOO0 =OOO0O0O0OO00O0OOO .read ()#line:73
    OO000O00O000000OO =int .from_bytes (OOO000O00O00OOOO0 [:4 ],byteorder ='little')#line:74
    O00O000OOOO0OO0OO =4 #line:75
    O0O0OO00OO000O0OO =len (OOO000O00O00OOOO0 )#line:76
    for O0O0OO0O00OOOO0OO in range (O00O000OOOO0OO0OO ,len (OOO000O00O00OOOO0 )):#line:77
        if OOO000O00O00OOOO0 [O0O0OO0O00OOOO0OO ]==0xFF :#line:78
            O0O0OO00OO000O0OO =O0O0OO0O00OOOO0OO #line:79
            break #line:80
    O0OO00OO00OOO0O0O =OOO000O00O00OOOO0 [O00O000OOOO0OO0OO :O0O0OO00OO000O0OO ]#line:81
    O0O0OO00O0OOO000O =zlib .crc32 (O0OO00OO00OOO0O0O )&0xFFFFFFFF #line:82
    if O0O0OO00O0OOO000O !=OO000O00O000000OO :#line:83
        print ('Ошибка при замене')#line:84
def generate_new_filename (O0O0OO0000O0OOOO0 ,O00O00OO0O000O00O ):#line:86
    O0O00O0O00O0OO0OO ,O0O00O000O000O0OO =os .path .splitext (O0O0OO0000O0OOOO0 )#line:87
    return f"{O0O00O0O00O0OO0OO}_{O00O00OO0O000O00O}{O0O00O000O000O0OO}"#line:88
def replace_values (OOOOO00O00O000O0O ,target =None ):#line:90
    OOO00O0O0OOOO00O0 =os .path .dirname (os .path .abspath (__file__ ))#line:91
    O00O0OO00OOO000O0 =os .path .dirname (OOO00O0O0OOOO00O0 )#line:92
    OOO0O00O00000OOOO =os .path .join (O00O0OO00OOO000O0 ,OOOOO00O00O000O0O )#line:93
    try :#line:95
        with open (OOO0O00O00000OOOO ,'rb')as OOOOO0000O0O00OOO :#line:96
            OO0O0000OOOOO00OO =OOOOO0000O0O00OOO .read ()#line:97
    except FileNotFoundError :#line:98
        print (f'Файл {OOO0O00O00000OOOO} не найден. Проверьте путь к файлу.')#line:99
        return #line:100
    if target =='server':#line:102
        OO0O0000OOOOO00OO ,O0OOO00OO0O0OOO0O ,O00OOOO000OOO0OO0 =replace_server (OO0O0000OOOOO00OO )#line:103
        if O0OOO00OO0O0OOO0O :#line:104
            if O00OOOO000OOO0OO0 =='net_to_ru':#line:105
                print ('Регион изменён с EU на EA')#line:106
            elif O00OOOO000OOO0OO0 =='ru_to_net':#line:107
                print ('Регион изменён с EA на EU')#line:108
        else :#line:109
            print ('Регион не найден')#line:110
        OO00000O0O0O0O000 =b'country='#line:111
        O00000OO0O0O0O00O =OO0O0000OOOOO00OO .find (OO00000O0O0O0O000 )#line:112
        if O00000OO0O0O0O00O !=-1 :#line:113
            O00O0OOO0OOO00OOO =O00000OO0O0O0O00O +len (OO00000O0O0O0O000 )#line:114
            O0O00OO00000000OO =OO0O0000OOOOO00OO .find (b'\x00',O00O0OOO0OOO00OOO )#line:115
            if O0O00OO00000000OO !=-1 :#line:116
                OOOO0O000O000O0O0 =OO0O0000OOOOO00OO [O00O0OOO0OOO00OOO :O0O00OO00000000OO ]#line:117
                if OOOO0O000O000O0O0 ==b'EA':#line:118
                    OO000OOO0O0OOO0O0 =b'EU'#line:119
                    OO0O0000OOOOO00OO =OO0O0000OOOOO00OO [:O00O0OOO0OOO00OOO ]+OO000OOO0O0OOO0O0 +OO0O0000OOOOO00OO [O00O0OOO0OOO00OOO +2 :O0O00OO00000000OO ]+OO0O0000OOOOO00OO [O0O00OO00000000OO :]#line:120
                    print ('Страна изменена с EA на EU')#line:121
                elif OOOO0O000O000O0O0 ==b'EU':#line:122
                    OO000OOO0O0OOO0O0 =b'EA'#line:123
                    OO0O0000OOOOO00OO =OO0O0000OOOOO00OO [:O00O0OOO0OOO00OOO ]+OO000OOO0O0OOO0O0 +OO0O0000OOOOO00OO [O00O0OOO0OOO00OOO +2 :O0O00OO00000000OO ]+OO0O0000OOOOO00OO [O0O00OO00000000OO :]#line:124
                    print ('Страна изменена с EU на EA')#line:125
        OO00O00000O0OOO0O ='server'#line:126
    else :#line:127
        OOOOO0O0O00000OOO ={'servicetag':(b'servicetag=',string .digits ),'sernumb':(b'sernumb=',string .digits ),'servicepass':(b'servicepass=',string .ascii_letters +string .digits ),'country':(b'country=',None )}#line:133
        O00O0OOO000OOO00O ={}#line:134
        for O000OO0OOOO0000OO ,(O0000O00OOO00OO00 ,O0OOOO0O00O000000 )in OOOOO0O0O00000OOO .items ():#line:135
            if target and O000OO0OOOO0000OO !=target :#line:136
                continue #line:137
            OO00OOOOOO00OO0O0 =OO0O0000OOOOO00OO .find (O0000O00OOO00OO00 )#line:138
            if OO00OOOOOO00OO0O0 !=-1 :#line:139
                O00O0OOO0OOO00OOO =OO00OOOOOO00OO0O0 +len (O0000O00OOO00OO00 )#line:140
                O0O00OO00000000OO =OO0O0000OOOOO00OO .find (b'\x00',O00O0OOO0OOO00OOO )#line:141
                O000000OO0O000O00 =OO0O0000OOOOO00OO [O00O0OOO0OOO00OOO :O0O00OO00000000OO ]if O0O00OO00000000OO !=-1 else b''#line:142
                if O000OO0OOOO0000OO =='country':#line:143
                    if O000000OO0O000O00 !=b'EA':#line:144
                        OO0O0000OOOOO00OO ,_O000O0O000O00OO0O =replace_field (OO0O0000OOOOO00OO ,O0000O00OOO00OO00 ,b'EA')#line:145
                        print (f'{O000OO0OOOO0000OO} заменён на EA')#line:146
                    continue #line:147
                elif O000OO0OOOO0000OO not in O00O0OOO000OOO00O :#line:148
                    if O000OO0OOOO0000OO =='sernumb':#line:149
                        O0OO00O000O000OOO =(O000000OO0O000O00 [:-4 ]+generate_random_string (4 ,O0OOOO0O00O000000 ).encode ())#line:150
                    else :#line:151
                        O0OO00O000O000OOO =generate_random_string (len (O000000OO0O000O00 ),O0OOOO0O00O000000 ).encode ()#line:152
                    O00O0OOO000OOO00O [O000OO0OOOO0000OO ]=O0OO00O000O000OOO #line:153
                else :#line:154
                    O0OO00O000O000OOO =O00O0OOO000OOO00O [O000OO0OOOO0000OO ]#line:155
                OO0O0000OOOOO00OO ,_O000O0O000O00OO0O =replace_field (OO0O0000OOOOO00OO ,O0000O00OOO00OO00 ,O0OO00O000O000OOO )#line:156
                print (f'{O000OO0OOOO0000OO} заменён на {O0OO00O000O000OOO.decode("utf-8", errors="ignore")}')#line:157
            else :#line:158
                print (f'{O000OO0OOOO0000OO} не найден.')#line:159
        if 'servicetag'in O00O0OOO000OOO00O :#line:160
            OOOOO0OOOO0O0O000 =O00O0OOO000OOO00O ['servicetag'][-4 :]#line:161
            OO00O00000O0OOO0O =OOOOO0OOOO0O0O000 .decode ('utf-8',errors ='ignore')#line:162
        else :#line:163
            OO00O00000O0OOO0O =target if target else 'out'#line:164
    OO0O0000OOOOO00OO ,O0O0000000OO0OOO0 =check (OO0O0000OOOOO00OO )#line:166
    O00O0O0OOOOOOO00O =generate_new_filename (OOOOO00O00O000O0O ,OO00O00000O0OOO0O )#line:167
    O00O0OO00OOO000O0 =os .path .dirname (os .path .dirname (os .path .abspath (__file__ )))#line:168
    O0OO00OO00000OOOO =os .path .join (O00O0OO00OOO000O0 ,O00O0O0OOOOOOO00O )#line:169
    with open (O0OO00OO00000OOOO ,'wb')as OOOOO0000O0O00OOO :#line:170
        OOOOO0000O0O00OOO .write (OO0O0000OOOOO00OO )#line:171
    verify (O0OO00OO00000OOOO )#line:172
if __name__ =="__main__":#line:174
    if len (sys .argv )<2 :#line:175
        sys .exit (1 )#line:176
    input_filename =sys .argv [1 ]#line:177
    target_name =sys .argv [2 ]if len (sys .argv )>2 else None #line:178
    replace_values (input_filename ,target_name )#line:179
