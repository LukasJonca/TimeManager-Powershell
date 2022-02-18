
#menu variable containing string
$menu = @"
Time Tracker
1. Find Process
2. Create Report
3. View Report
4. Update Report
5. Quit
"@

$start = get-date
<#
.SYNOPSIS
    Performs search for process
.DESCRIPTION
    Performs search for specific process' and outputs when it was started and how long it has been running for.
.EXAMPLE
    search -path *Note*
#>
function search(){
    param(
    
    [parameter(Mandatory=$true, Helpmessage="Provide name", valuefrompipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string]$path)
    #option 1 search
    
     #looks for process gets and retruns running time.
     $process | ForEach-Object{
          if($_.ProcessName -like "$path"){
                try{
                  $_.runningTime = (NEW-TIMESPAN –Start ([dateTime]($_.startTime)) –End (get-date))#((get-date) - [dateTime]($_.startTime))
                 }catch{}
                  $_| Format-List -property processName, runningTime, startTime
               
             }
      }
}

<#
.SYNOPSIS
    Prints the process' save on a file
.DESCRIPTION
   Prints the process' save on a file in a specific path to the console
.EXAMPLE
    print -path times.txt
#>
function print(){
      param(
    
      [parameter(Mandatory=$true, Helpmessage="Provide path")]
      [ValidateNotNullOrEmpty()]
      [string]$path)

      $tmp = get-content -raw $path | ConvertFrom-StringData

      #print table
      $tmp | format-table
}

<#
.SYNOPSIS
    Accesses files to either update contnt or create a file for running times
.DESCRIPTION
    Accesses files to either update contnt or create a file for running times
.EXAMPLE
    toFile -path save.txt
    toFile -path save.txt -update
#>
function toFile(){
    [CmdletBinding()]

    param(
        #Save path
        [Parameter(Mandatory=$true, Helpmessage="Provide path")]
        [string]$path,
        [switch]$update
       
    )

    $ht = @{}

     #go tthrough process'
     $process | ForEach-Object -erroraction 'silentlycontinue'{

           try{
                $ht.add($_.name, ((get-date) - [dateTime]($_.startTime)))
            }catch{}

      }

      if ($update -eq $false){ 
          #clear file (ignore errors)
          try{Clear-Content $path -erroraction 'silentlycontinue'}catch {continue;}
          #saves hash table path
          $ht.keys | ForEach-Object {
                try{
                    $str = $_ + "=" + $ht[$_]
                    $str >> $path
                 }catch{}
           }
    }else{
        $tmp = @{}

            #get file
            $tmp = get-content -raw $path | ConvertFrom-StringData
            
            #$hin | format-list
            #clear file
            Clear-Content $path

            #add exisiting report with current times
            $ht.keys | ForEach-Object {
                #if process time is not null
                if($ht[$_] -ne $null -and $tmp[$_] -ne $null){
                    #add process' and update file
                    $tmp[$_] = ($ht[$_]) + ($tmp[$_])
                    $str = $_ + "=" + $tmp[$_]
                    $str >> $path

                #if process is null
                }elseif($tmp[$_] -ne $null){
                    
                    #get process and add to file
                    $str = $_ + "=" + $ht[$_]
                    $str >> $path
                }
            }
    }
}


#while option not equal to 5
do{
    #menu
    $menu
    $in = read-host "Enter"

    #gets current process'
    $process = get-process

    #creates noteproperties for process'
    $process | Add-member -MemberType NoteProperty -Name "runningTime" -value 0
    $process | Add-member -MemberType NoteProperty -Name "lastStartTime" -value 0

    #$process | get-member *start*

  
    switch($in){
        1 { 
            $p = read-host "Search"
            if($p -ne ""){ search -path $p}
            else{search}

           
        }
        2 { #option 2 create report
            #gets destinbation path
            $path = read-host "Path"
            toFile -path $path -errorAction 'silentlycontinue'
            #
            #Set-Content -path $path -value "$ht.key=$ht.value"
            #$ht | out-file $path -Encoding utf8
        }
        3 { #option 3 view existing report
            #get path and data from path
            $path = read-host "Path"
            print -path $path
           }
        4 { #option 4 update existing report (if all processes were stopped)
            #get path
            
            $path = read-host "Path"
            toFile -path $path -update -errorAction 'silentlycontinue'
            #
            #$tmp | out-file $path -Encoding utf8

           }

           #option 5 exit
        5 {"Goodbye!"}

           #default for invalid input
        default {"Inavild Input"}
    }
}while($in -ne 5)