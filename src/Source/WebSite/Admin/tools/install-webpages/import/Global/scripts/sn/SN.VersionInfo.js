﻿// resource VersionInfo

$(function () {
    var applicationsDataSource, installedPackagesDataSource, assembliesDataSource, officialSensenetVersion, assemblies, assemblyArray = [];

    $.ajax({
        url: "/OData.svc/('Root')/GetVersionInfo/",
        dataType: "json",
        async: false,
        success: function (result) {
            assemblies = result.Assemblies;
            officialSensenetVersion = result.OfficialSenseNetVersion;
            installedPackagesDataSource = new kendo.data.DataSource({
                data: result.InstalledPackages,
                schema: {
                    model: {
                        fields: {
                            Id: { type: "number" },
                            Name: { type: "string" },
                            Edition: { type: "string" },
                            Description: { type: "string" },
                            AppId: { type: "string" },
                            PackageLevel: { type: "number" },
                            PackageType: { type: "number" },
                            ReleaseDate: { type: "date" },
                            ExecutionDate: { type: "date" },
                            ExecutionResult: { type: "number" },
                            ApplicationVersion: { type: "string" },
                            SenseNetVersion: { type: "string" },
                            ExecutionError: { type: "string" }
                        }
                    }
                }
            }),
            applicationsDataSource = new kendo.data.DataSource({
                data: result.Applications,
                schema: {
                    model: {
                        fields: {
                            Name: { type: "string" },
                            Edition: { type: "string" },
                            AppId: { type: "string" },
                            Version: { type: "string" },
                            AcceptableVersion: { type: "string" },
                            Description: { type: "string" }
                        }
                    }
                }
            }),
            assembliesDataSource = new kendo.data.DataSource({
                data: result.Assemblies,
                detailInit: detailInit,
                dataSource: assembliesDataSource,
                schema: {
                    model: {
                        fields: {
                            Namm: { type: "string" },
                            IsDynamic: { type: "boolean" },
                            CodeBase: { type: "string" },
                            Version: { type: "string" }
                        }
                    }
                },
            });

            createSensenetVersionInfoBox(officialSensenetVersion);
            createVersionGrids(applicationsDataSource, installedPackagesDataSource, assembliesDataSource);
        }
    });

    function createSensenetVersionInfoBox(info) {
        var $infobox = $('#infoBox');
        $infobox.html('');
        for (var obj in info) {
            var value = info[obj];
            if (value !== null)
                var $row = $('<div><label style="font-weight: bold; color: #007dc6">' + SN.Resources.VersionInfo[obj] + '</label>' + ': ' + '<span>' + value + '</span></div>').appendTo($infobox);
        }
    }

    function createVersionGrids(appDataSource, packageDataSource) {
        $("#installedPackagesGrid").kendoGrid({
            dataSource: packageDataSource,
            scrollable: false,
            sortable: true,
            filterable: false,
            columns: [
                { field: "Id", title: "Id" },
                { field: "Name", title: SN.Resources.VersionInfo["Name"] },
                { field: "Edition", title: SN.Resources.VersionInfo["Edition"] },
                { field: "Description", title: SN.Resources.VersionInfo["Description"] },
                { field: "AppId", title: SN.Resources.VersionInfo["AppId"] },
                { field: "PackageLevel", title: SN.Resources.VersionInfo["PackageLevel"] },
                { field: "PackageType", title: SN.Resources.VersionInfo["PackageType"] },
                { field: "ReleaseDate", title: SN.Resources.VersionInfo["ReleaseDate"], format: "{0:MM/dd/yyyy}" },
                { field: "ExecutionDate", title: SN.Resources.VersionInfo["ExecutionDate"], format: "{0:MM/dd/yyyy}" },
                { field: "ExecutionResult", title: SN.Resources.VersionInfo["ExecutionResult"] },
                { field: "ApplicationVersion", title: SN.Resources.VersionInfo["ApplicationVersion"] },
                { field: "SenseNetVersion", title: SN.Resources.VersionInfo["SenseNetVersion"] },
                { field: "ExecutionError", title: SN.Resources.VersionInfo["ExecutionError"] }
            ],
            dataBound: gridDataBound
        });

        $("#applicationsGrid").kendoGrid({
            dataSource: appDataSource,
            scrollable: false,
            sortable: true,
            filterable: false,
            columns: [
                { field: "Name", title: SN.Resources.VersionInfo["Name"] },
                { field: "Edition", title: SN.Resources.VersionInfo["Edition"] },
                { field: "AppId", title: SN.Resources.VersionInfo["AppId"] },
                { field: "Version", title: SN.Resources.VersionInfo["Version"] },
                { field: "AcceptableVersion", title: SN.Resources.VersionInfo["AcceptableVersion"] },
                { field: "Description", title: SN.Resources.VersionInfo["Description"] }
            ],
            dataBound: gridDataBound
        });

        $.each(assemblies, function () {
            if (typeof this === 'object') {
                assemblyArray.push(this);
            }
        });

        var $assembliesMainGrid = $('<table></table>').appendTo('#assembliesGrid');
        for (var obj in assemblies) {
            var $row = $('<tr><td>' + obj + '</td></tr>').appendTo($assembliesMainGrid);
        }

        $("#assembliesGrid").kendoGrid({
            scrollable: false,
            sortable: true,
            filterable: false,
            columns: [
                    { field: "Name", title: SN.Resources.VersionInfo["Name"] }
            ],
            detailInit: function (e) {
                detailInit(e, this);
            },
            dataBound: gridDataBound
        });

    }

    function gridDataBound(e) {
        var grid = e.sender;
        if (grid.dataSource.total() == 0) {
            var colCount = grid.columns.length;
            $(e.sender.wrapper)
                .find('tbody')
                .append('<tr class="kendo-data-row"><td colspan="' + colCount + '" class="no-data">' + SN.Resources.VersionInfo["NoData"] + '</td></tr>');
        }
    };

    function detailInit(e) {

        for (var obj in assemblies) {
            if (e.data.Name === obj) {
                initializeDetailGrid(e, assemblies[obj]);
            }
        }
    }

    function initializeDetailGrid(e, result) {
        var moreChildren = result[0].HasChildren;
        for (var i = 0; i < e.length; i++) {
            for (var j = 0; j < result.length; j++) {
                if (e[i].Name === result[j].Name)
                    result = result[j];
            }
        }
        var gridBaseOptions = {
            dataSource: result,
            scrollable: false,
            sortable: true,
            columns: [
                    { field: "Name", title: SN.Resources.VersionInfo["Name"] },
                    { field: "IsDynamic", title: SN.Resources.VersionInfo["Is Dynamic"] },
                    { field: "CodeBase", title: SN.Resources.VersionInfo["Code Base"] },
                    { field: "Version", title: SN.Resources.VersionInfo["Version"] }
            ]
        };

        var gridOptions = {};
        if (moreChildren) {
            gridOptions = $.extend({}, gridBaseOptions, { detailInit: detailInit });
        } else {
            gridOptions = gridBaseOptions;
        }
        $("<div/>").appendTo(e.detailCell).kendoGrid(gridOptions);
    }

});