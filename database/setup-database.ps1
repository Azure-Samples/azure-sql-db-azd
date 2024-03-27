Invoke-WebRequest -Uri https://aka.ms/sqlpackage-linux -OutFile sqlpackage.zip

Expand-Archive ./sqlpackage.zip sqlpackage/

chmod a+x ./sqlpackage/sqlpackage

./sqlpackage/sqlpackage /version

Write-Host "Downloading dacpacs"

Invoke-WebRequest -Uri https://github.com/azure-samples/azure-sql-db-session-recommender-v2/raw/main/database/session_recommender_v2.dacpac -OutFile session_recommender_v2.dacpac
Invoke-WebRequest -Uri https://github.com/azure-samples/azure-sql-db-session-recommender-v2/raw/main/database/master.dacpac -OutFile master.dacpac

Write-Host "Deploying database to $Env:DBSERVER with name $Env:DBNAME"

./sqlpackage/sqlpackage `
    /Action:Publish `
    /SourceFile:"session_recommender_v2.dacpac" `
    /TargetDatabaseName:"$Env:DBNAME" `
    /TargetServerName:"$Env:DBSERVER" `
    /TargetUser:"$Env:SQLADMIN" `
    /TargetPassword:"$Env:SQLCMDPASSWORD" `
    /v:APP_USER_PASSWORD="$Env:APP_USER_PASSWORD"
