#!/usr/bin/env python
#coding=utf-8

# lua 配置导表工具

# 依赖:
# 2 xlrd
##


import xlrd # for read excel
import sys
import codecs
import os
import os.path
import platform

reload(sys)
sys.setdefaultencoding('utf-8')

types = []
keys = []
def get_value(sheet, row, col):
    try :

        t = types[col - 1]
        value =  sheet.cell_value(row, col)

        tp = t[0]

        if value == "" and tp == "*":
            return None

        if tp == "*":
            t = t[1:]

        if t == "int":
            if value == "":
                value = 0
            return "%d" % value
        elif t == "number":
            if value == "":
                value = 0.0
            return "%.2f" % value
        elif t == "string":
            if value == "":
                value = ""
            return "\"" + str(value) + "\""
        elif t == "lstring":
            if value == "":
                value = ""
            return "[[" + str(value) + "]]"
        elif t == "key":
            if value == "":
                value = ""
            return "\"" + str(value) + "\""
        elif t == "array":
            if value == "":
                value = "{}"
            else:
                count = 0
                for char in value:
                    if char == "[":
                        count = count + 1
                    elif char == "]":
                        count = count - 1
                if value[0] != "[" or value[-1] != "]" or count != 0:
                    print(u"请检查%s列%d行table的数据:%s" % (keys[col-1], row+1, value))
            return value.replace('[', '{').replace(']', "}")
        elif t == "map":
            if value == "":
                value = "{}"
            else:
                count = 0
                for char in value:
                    if char == "{":
                        count = count + 1
                    elif char == "}":
                        count = count - 1
                if value[0] != "{" or value[-1] != "}" or count != 0:
                    print(u"请检查%s列%d行table的数据:%s" % (keys[col-1], row+1, value)) 
            return value.replace(':', '=')
        elif t == "code":
            if value == "":
                value = "nil"
            return str(value)
        else:
            return "nil"
        
    except BaseException:
        print(u"请检查%s列%d行的数据:%s" % (keys[col-1], row+1, value)) 
        return "nil"

def xls_to_lua(filename):
    data = "-- 此配置文件由脚本导出，请勿手动修改\n"
    data = data + "return {\n"

    workbook = xlrd.open_workbook(filename)

    for sheet in workbook.sheets():
        if sheet.name.find("#")<0:
            continue
        # 行数和列数
        row_count = len(sheet.col_values(0))
        col_count = len(sheet.row_values(0))
        # print("共%d行%d列"% (row_count, col_count))

        global types
        types = []
        for col_idx in range(1, col_count):
            t = sheet.cell_value(0, col_idx)
            rt = t
            if t != "" and t[0] == "*":
                t = t[1:]

            if t != "int" and t != "number" and t != "string" and t != "array" and t != "map" and t != "code" and t != "key" and t != "lstring" and t != "":
                print(u"请检查第%d列的类型%s" % (col_idx, t))
                return ""

            types.append(rt)


        global keys
        keys = []
        for col_idx in range(1, col_count):
            keys.append(str(sheet.cell_value(1, col_idx)))

        for row_idx in range(3, row_count):
            if sheet.cell_value(row_idx, 0) != "ignore" and sheet.cell_value(row_idx, 1) != "" and get_value(sheet, row_idx, 1) != "nil":
                data = data + "    [" + get_value(sheet, row_idx, 1) + "] = {"
                for col_idx in range(1, col_count):
                    # print(types[col_idx-11])
                    if types[col_idx-1] != "":
                        value = get_value(sheet, row_idx, col_idx)
                        if value != None:
                            data = data + keys[col_idx-1] + " = " + str(value) + ", "
                data = data + "},\n"
    data = data + "}"
    return data

def need_export(src, dst):
    # print(os.stat(src).st_mtime)
    # print(os.stat(dst).st_mtime)
    # if not os.path.exists(dst):
    #     return True
    # return os.stat(src).st_mtime > os.stat(dst).st_mtime
    return True


if __name__ == '__main__' :
    """入口"""

    xls_folder =  sys.argv[1]
    export_folder = sys.argv[2]

    for parent,dirnames,filenames in os.walk(xls_folder):    #三个参数：分别返回1.父目录 2.所有文件夹名字（不含路径） 3.所有文件名字
        for filename in filenames:                        
            if filename.find('.svn') < 0 and filename.find('$') < 0 and filename.find('.xls') > 0:
                path = os.path.join(parent,filename)
                export_filename = filename.replace('.xlsx','.lua') 
                export_filename = export_filename.replace('.xls','.lua') 
                export_path = os.path.join(export_folder,export_filename)
                if need_export(path, export_path):
                    print(filename + " => " + export_folder + "/" +  export_filename)
                    data = xls_to_lua(path)
                    file = codecs.open(export_path, 'w+', 'utf-8')
                    file.write(data)
                    file.close()

    print ("导出完成")

