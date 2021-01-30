# There are two functions included.  One with and without a progress bar.

#--------------------------------------------------------------------
# This just downloads the file (no progress bar)
function funcDownloadFileViaHttp( [string] $sFullNameDownload, [string] $sDestinationPath, [string] $sFileName='' ) {
    <#  .DESCRIPTION
            Download a file via HTTP(s).  PS v2 compatible.
            This process will OVERWRITE a file with the same name in the destination
            Large file sizes and long download times are supported
        .PARAMETER sFullNameDownload
            Full name download location
        .PARAMETER sDestinationPath
            Destination path for the file after download
        .PARAMETER sFileName
            Override the automatically calculated file name in sFullNameDownload with this specified name.
        .RETURNS
            The destination file object
    #>
    $oHttpWebRequest = [System.Net.HttpWebRequest]::Create($sFullNameDownload)
    $oHttpWebRequest.KeepAlive = $true
    $oHttpWebResponse = $oHttpWebRequest.GetResponse()
    if ( $oHttpWebResponse.StatusCode.value__ -eq 200) {
        if ($sFileName -eq '') {
            $sFileName = $oHttpWebRequest.RequestUri.Segments[-1]
        } 
        $sDestinationPath = (Resolve-Path $sDestinationPath).Path
        $sFileFullNameFinal = Join-Path $sDestinationPath $sFileName
        $oStream = $oHttpWebResponse.GetResponseStream()
        [byte[]] $buffer1 = New-Object byte[] 4096
        $oStreamDest = New-Object System.IO.FileStream ($sFileFullNameFinal,[IO.FileMode]::Create)
        do {
            # This process will OVERWRITE a file with the same name in the destination
            $iByteCountFilled = $oStream.Read($buffer1,0,($buffer1.Length))
            $oStreamDest.Write($buffer1,0,$iByteCountFilled)
        } while ($iByteCountFilled -ne 0)
        $oStreamDest.Close()
        $oStream.Close()
        $oStream.Dispose()
        $oFile = Get-Item $sFileFullNameFinal
    } else {
        throw 'Bad response from web server'
    }
    return ,$oFile
} # End of function funcDownloadFileViaHttp


#--------------------------------------------------------------------
# Downloads file and displays a progress bar with configurable refresh
function funcDownloadFileViaHttp( [string] $sFullNameDownload, [string] $sDestinationPath, [string] $sFileName='', [int] $iProgressDelay=1 ) {
    <#  .DESCRIPTION
            Download a file via HTTP(s).  PS v2 compatible.
            This process will OVERWRITE a file with the same name in the destination
            Large file sizes and long download times are supported
        .PARAMETER sFullNameDownload
            Full name download location
        .PARAMETER sDestinationPath
            Destination path for the file after download
        .PARAMETER sFileName
            Override the automatically calculated file name in sFullNameDownload with this specified name.
        .PARAMETER iProgressDelay
            How many seconds to wait to update the progress meter
        .RETURNS
            The destination file object
    #>
    $oHttpWebRequest = [System.Net.HttpWebRequest]::Create($sFullNameDownload)
    $oHttpWebRequest.KeepAlive = $true
    $oHttpWebResponse = $oHttpWebRequest.GetResponse()
    if ( $oHttpWebResponse.StatusCode.value__ -eq 200) {
        if ($sFileName -eq '') {
            $sFileName = $oHttpWebRequest.RequestUri.Segments[-1]
        }
        $sDestinationPath = (Resolve-Path $sDestinationPath).Path
        $sFileFullNameFinal = Join-Path $sDestinationPath $sFileName
        $oStream = $oHttpWebResponse.GetResponseStream()
        $iContentLength = $oHttpWebResponse.ContentLength  # Progress
        $iByteCountStatus = 0  # Progress
        [byte[]] $buffer1 = New-Object byte[] 4096
        $oStreamDest = New-Object System.IO.FileStream ($sFileFullNameFinal,[IO.FileMode]::Create)
        $dblFutureTime = [double] (Get-Date -UFormat %s)
        $iProgTestDelay = $iProgTestDelayLast = 1000 * $iProgressDelay  # Number of loops before we even check the datetime
        do {
            # This process will OVERWRITE a file with the same name in the destination
            $iByteCountFilled = $oStream.Read($buffer1,0,($buffer1.Length))
            $oStreamDest.Write($buffer1,0,$iByteCountFilled)
            $iByteCountStatus += $iByteCountFilled  # Progress
            # Add a delay in displaying the progress.  This allows faster downloads
            if ( $iProgTestDelay -le 0 ) {
                $dblTimeNow = [double] (Get-Date -UFormat %s)
                $bolProgDelayOvershoot = $false
                if ( $dblTimeNow -ge $dblFutureTime ) {
                    # Timer has elapsed, update progress bar
                    if ( $dblTimeNow -ge ($dblFutureTime+$iProgressDelay) ) {
                        # We have overshot our display time. This happens on slow links. 
                        # Need to decrease the loop counter so progress stays on time
                        $bolProgDelayOvershoot = $true
                    }
                    $sProgressStatus = @("[",$iByteCountStatus,"/",$iContentLength,"] bytes completed") -join ""  # Progress
                    Write-Progress -Activity "Downloading" -Status $sProgressStatus  `
                        -PercentComplete ([int]($iByteCountStatus/$iContentLength * 100))  # Progress
                    $dblFutureTime = ([double] (Get-Date -UFormat %s)) + $iProgressDelay
                }
                if ( $bolProgDelayOvershoot ) {
                    # This will decrease the number of loops that occur prior to datetime check
                    # Eventually the loop delay will adjust into the iProgressDelay value
                    $iProgTestDelay = $iProgTestDelayLast = [int] ($iProgTestDelayLast/3)
                } else {
                    $iProgTestDelay = $iProgTestDelayLast
                }
            }
            $iProgTestDelay--
        } while ($iByteCountFilled -ne 0)
        $oStreamDest.Close()
        $oStream.Close()
        $oStream.Dispose()
        $oFile = Get-Item $sFileFullNameFinal
    } else {
        throw 'Bad response from web server'
    }
    return ,$oFile
} # End of function funcDownloadFileViaHttp

