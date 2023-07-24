1. Open the ClientID and Client Company files. Replace the X-values with your values.

2. Open the .pq file and recompile the .mez file (I use the Power Query SDK extension for VS Code to recompile)

3. Move \bin\AnyCPU\Debug\BuildingConnected.mez to [Documents]\Power BI Desktop\Custom Connectors (you may have to create this folder)

4. Restart Power BI Desktop.

Building Connected should now appear as a connection in the menu when you click "Get Data"

--
Note: 

  Until a connection is made official by Microsoft at the request of Building Connected, this connection will only work on the Desktop version, and you must refresh data from 
the Desktop version of Power BI on a Desktop with the above .Mez file in the Custom Connector Folder.

--