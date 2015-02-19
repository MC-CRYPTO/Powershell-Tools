

Param(
$InputFile = "$PSScriptRoot\input.txt",
$OutputFile = "$PSScriptRoot\output.csv"
)

"start"

function check-bin($hostname,$outputfile)
{
    $data = "BIN Detected"

    if(test-path "\\$hostname\c$\Documents and Settings\All Users\Application data\mozilla\*.bin")
    {
        output-data -hostname $hostname -data $data -outputfile $outputfile
        return $true
    }
    else
    {
        return $false
    }
}


function check-com($hostname,$outputfile)
{
    $data = "COM Detected"

    if(test-path "\\$hostname\c$\Windows\System32\com\svchost.exe")
    {
        output-data -hostname $hostname -data $data -outputfile $outputfile
        return $true
    }
    else
    {
        return $false
    }
}


function check-bin2($hostname,$outputfile)
{
    $data = "BIN2 Detected"

    if(test-path "\\$hostname\c$\ProgramData\mozilla\*.bin")
    {
        output-data -hostname $hostname -data $data -outputfile $outputfile
        return $true
    }
    else
    {
        return $false
    }
}


function check-paexec($hostname,$outputfile)
{
    $data = "Paexec Detected"

    if(test-path "\\$hostname\c$\Windows\paexec*")
    {
        output-data -hostname $hostname -data $data -outputfile $outputfile
        return $true
    }
    else
    {
        return $false
    }
}



function check-com64($hostname,$outputfile)
{
    $data = "COM64 Detected"

    if(test-path "\\$hostname\c$\Windows\Syswow64\com\svchost.exe")
    {
        output-data -hostname $hostname -data $data -outputfile $outputfile
        return $true
    }
    else
    {
        return $false
    }
}

function check-com64($hostname,$outputfile)
{
    $data = "COM64 Detected"

    if(test-path "\\$hostname\c$\Windows\Syswow64\com\svchost.exe")
    {
        output-data -hostname $hostname -data $data -outputfile $outputfile
        return $true
    }
    else
    {
        return $false
    }
}

function check-service($hostname,$outputfile,$credential)
{
    $servicename = "Sys$"
    $data = "Sys$ Service exists"

    if(get-wmiobject win32_service -ComputerName $hostname -Credential $credential | where{$_.name -eq $servicename})
    {
      output-data -hostname $hostname -data $data -outputfile $outputfile
      return $true
    }
    else
    {
        return $false
    }
}








function output-data($hostname,$data,$outputfile)
{
    "$hostname,$data" | out-file -FilePath $outputfile -Encoding ascii -Append -Force
}

function Check-Connections($hostname)
{
    $drives = get-psdrive | where {$_.DisplayRoot -match $hostname}

    if($drives)
    {
        $drives | Remove-PSDrive -Force -Confirm:$false -Scope Global
    }
}


function Connect-hostname($hostname,$credential)
{
    New-PSDrive -PSProvider FileSystem -Name hostconnection -Root \\$hostname\c$ -Credential $credential -Confirm:$false -Scope Global
    if($?)
    {
        return $true
    }
    else
    {
        return $false
    }
}

function disconnect-hostname
{
    Remove-PSDrive -Name hostconnection -Force -Confirm:$false
        if($?)
    {
        "Disconnected"
        return $true
    }
    else
    {
        return $false
    }
}






[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic’)


#Check for existence of input file

if(test-path $InputFile)
{
    Write-Host -ForegroundColor green -Object "Input file found"
}
else
{
    write-host -ForegroundColor red -Object "ERROR: Input file not found at $Inputfile"
    return
}



#Check for existence of output file
if(test-path $OutputFile)
{
    write-host -ForegroundColor Yellow -Object "WARNING: Output file already exists"
    $overwrite = [Microsoft.VisualBasic.Interaction]::MsgBox("WARNING: Output file $outputfile already exists `r`n`r`nOverwrite?",4,"WARNING")

    if($overwrite -eq "yes")
    {
        write-host -ForegroundColor Cyan -Object "Output file will be overwritten"
       
    }
    else
    {
        write-host -ForegroundColor Red -Object "Quitting due to existing output file. Please try again."
        return
    }

}


#create file, or overwrite existing

 new-item -Path $OutputFile -ItemType File -Force -Confirm:$false



#Getting hostnames from file
write-host -ForegroundColor Cyan -Object "Getting contents of input file"
$hosts = get-content -Path $InputFile | where {$_ -ne ""}
$length = $hosts.Length
write-host -ForegroundColor Cyan -Object "There are $length lines in the input file"


#Ask for credentials
write-host -ForegroundColor Cyan -Object "Requesting credentials to connect to remote hosts. Please provide an Admin account that has rights over the remote hosts"
$cred = Get-Credential





#Run file check on each host

foreach($item in $hosts)
{
    write-host ""
    write-host -ForegroundColor Cyan -Object "Now scanning: $item"

    write-host -ForegroundColor Cyan -Object "Connecting..."

    Check-Connections -hostname $item

    $Connection = Connect-hostname -hostname $item -credential $cred
    if($Connection)
    {
        write-host -ForegroundColor green -Object "Connected"
    }
    else
    {
        Write-Host -ForegroundColor Red -Object "Failed to connect to $item. Skipping"
        output-data -hostname $item -data "Failed to connect" -outputfile $OutputFile
        continue
    }



    $bin = check-bin -hostname $item -outputfile $OutputFile
    $bin2 = check-bin2 -hostname $item -outputfile $OutputFile
    $com = check-com -hostname $item -outputfile $OutputFile
    $com64 = check-com64 -hostname $item -outputfile $OutputFile
    $paexec = check-paexec -hostname $item -outputfile $OutputFile
    $service = check-service -hostname $item -outputfile $OutputFile -credential $cred

    $disconnect = disconnect-hostname
    
    if($bin -or $bin2 -or $com -or $com64 -or $paexec -or $service)
    {
        Write-Host -ForegroundColor Magenta -Object "Possible virus evidence found on $item. Logged in $outputfile."
    }
    else
    {
        write-host -ForegroundColor Green -Object "$item Ok"
        output-data -hostname $item -data "Ok" -outputfile $outputfile
    }











}



