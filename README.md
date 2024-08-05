# LabConfig
 Script to setup school computer lab computers.
 
 Instructions:

1. Make sure,
    - Student account is already created/
    - You are in the administrator account (BCCS).
    - Lockscreen is already set. (I couldn't find a reliable way to set the lock screen with the script)
2. Download and run the RunThis.bat file.
3. Input the passwords for student and BCCS accounts. You can remove this by setting the followuing variables and replacing 'BCCS_PASSWORD' and 'STUDENT_PASSWORD'.
    - `$script:BCCSPassword = ConvertTo-SecureString -String 'BCCS_PASSWORD' -AsPlainText -Force`
    - `$script:StudentPassword = ConvertTo-SecureString -String 'STUDENT_PASSWORD' -AsPlainText -Force`
4. Input the computer name (hostname). You can remove this by setting the following variable and replacing 'HOSTNAME'.
    - `$script:ComputerName = 'HOSTNAME'`
