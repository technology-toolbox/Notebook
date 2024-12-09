# W10-2019-06

Tuesday, August 13, 2019\
3:27 PM

<table>
<tr>
<td valign='top'>
<p>Before patching</p>
</td>
<td valign='top'>
<p>14.2</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>After patching</p>
</td>
<td valign='top'>
<p>11.3</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Dism.exe /online /Cleanup-Image /StartComponentCleanup</p>
</td>
<td valign='top'>
<p>12.8</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Dism.exe /online /Cleanup-Image /StartComponentCleanup (after reboot)</p>
</td>
<td valign='top'>
<p>12.9</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase</p>
</td>
<td valign='top'>
<p>12.9</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase (after reboot)</p>
</td>
<td valign='top'>
<p>12.9</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Dism.exe /online /Cleanup-Image /SPSuperseded</p>
</td>
<td valign='top'>
<p>Error: 13</p>
<p>Could not enumerate Service Pack on machine.</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>DISM.exe /Online /Cleanup-image /Restorehealth</p>
</td>
<td valign='top'>
<p>11.3</p>
</td>
</tr>
</table>
