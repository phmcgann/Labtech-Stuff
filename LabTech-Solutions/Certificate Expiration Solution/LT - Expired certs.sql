
INSERT INTO `Agents` (`Name`,`LocID`,`ClientID`,`ComputerID`,`DriveID`,`CheckAction`,`AlertAction`,`AlertMessage`,`ContactID`,`interval`,`Where`,`What`,`DataOut`,`Comparor`,`DataIn`,`LastScan`,`LastFailed`,`FailCount`,`IDField`,`AlertStyle`,`Changed`,`Last_Date`,`Last_User`,`ReportCategory`,`TicketCategory`,`Flags`) Values('LT - Expired Certs','0','0','0','0','0','1','%NAME% %STATUS% on %CLIENTNAME%\\%COMPUTERNAME% at %LOCATIONNAME% for %FIELDNAME% result %RESULT%.!!!%NAME% %STATUS% on %CLIENTNAME%\\%COMPUTERNAME% at %LOCATIONNAME% for %FIELDNAME% result %RESULT%.','0','86400','lt_certs','ExpiresIn','1','4','1','2015/10/13 08:37:49','2014/10/13 08:38:12','3','','7','0','2014/10/21 10:20:44','Admin@Desktop.home','9','0','0');