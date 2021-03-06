#####################################################################################
#Script Created by Phillip Marshall													#
#Creation Date 6/5/14																#
#Revision 2																			#
#Revisions Changes - Added Commenting and cleaned up formatting.					#
#																					#
#Description - This script will pull exchange mailbox information from a Exchange	#
#2007 box and return it into a format that can be inserted into a custom table in	#
#the LabTech monitoring Database.													#
#####################################################################################

Function ExchangeMailboxInfo
{

            #Creates the two sections of the MySQL insert statement for the LabTech Database.
            $MailBoxValues = ""
            $MailboxInsert = "REPLACE INTO ExchangeMailboxes (AgentID,ExchangeServerName,Databasename,Mailboxname,TotalMailBoxItemCount,TotalMailBoxSize)"
            
    Try
    {
        #Adds 2007 Exchange Snapin
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
    }
    Catch
    {}

     Try
    {
        #Adds 2010 Exchange Snapin
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
    }
    Catch
    {}

            #Gets the information for all Mailboxes.
            get-mailbox | % { 
                $mailboxinfo = get-MailboxStatistics -Identity $_.SamAccountName;
                $MailBoxName = $_.DisplayName;
                $DatabaseName = $_.Database
                $TotalItemCount = $mailboxinfo.ItemCount
                $TotalMailBoxSize = $mailboxinfo.TotalItemSize.Value.ToMB()
                    IF ($MailBoxValues -eq "")
                    {
                        $MailboxValues = " VALUES('%computerid%','%computername%',`'$DatabaseName`',`'$Mailboxname`',`'$TotalItemCount`',`'$TotalMailBoxSize`')" 
                    }
                    Else
                    {
                        $MailBoxValues = $MailboxValues + ",('%computerid%','%computername%',`'$DatabaseName`',`'$Mailboxname`',`'$TotalItemCount`',`'$TotalMailBoxSize`')" 
                    }
                            }

            #Outputs the insert statements to a file to be pulled in VIA a LabTech Script.                
            IF ($MailBoxValues -eq $NULL)
            {
                $MailBoxValues = "No Values were retrieved"
                out-file -filepath C:\Windows\temp\mailboxstats.txt -inputobject $Mailboxvalues
            }

            Else
            {
                $MailboxInsert = $MailboxInsert + $MailBoxValues
                out-file -filepath C:\Windows\temp\mailboxstats.txt -inputobject $Mailboxinsert
            }
}

ExchangeMailboxInfo