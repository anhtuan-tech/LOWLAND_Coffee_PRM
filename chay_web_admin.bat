@echo off
chcp 65001 >nul
echo ========================================================
echo   HE THONG QUAN TRI WEB ADMIN - LOWLAND COFFEE
echo ========================================================
echo Dang mo trang Web Admin tren trinh duyet...
start "" "%~dp0web_admin\index.html"
echo.
echo Da mo thanh cong file: %~dp0web_admin\index.html
echo Ban co the dang nhap voi tai khoan: admin@lowlandcoffee.com
echo.
pause

