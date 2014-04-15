$ ->
  Highcharts.setOptions
    global:
      useUTC: false
      timezoneOffset: 9
    chart:
      type: 'line'
      zoomType: 'x'
    credits:
      enabled: false
    legend:
      enabled: false
    title:
      text: ''
    yAxis:
      title:
        enabled: false
    xAxis:
      title:
        enabled: false
      labels:
        enabled: false
    tooltip:
      shared: true
      crosshairs:
        color: '#ccc'
    plotOptions:
      series:
        lineWidth: 1
        marker:
          radius: 0

  defaultOptions =
    dataType: 'json'
    domain: 'day'
    subDomain: 'hour'
    start: new Date(moment().add('days', -9).format())
    cellSize: 12
    cellPadding: 3
    range: 10
    # range: 10
    # rowLimit: 1
    # domainGutter: 0
    # verticalOrientation: true
    # cellSize: 20
    # cellPadding: 5
    # label:
    #   position: 'left'
    # legendHorizontalPosition: 'right'
    browsing: true
    cellRadius: 0
    highlight: ['now', new Date()]
    subDomainTextFormat: (date, value) ->
      value
    onClick: (date, value) ->
      $('#display').text("#{moment(date).format()}: #{value}")

  cal_all = new CalHeatMap()
  options =
    itemSelector: '#cal-heatmap-all'
    data: 'records/all'
    legend: [50, 100, 150, 200]
    nextSelector: "#all-next",
    previousSelector: "#all-previous"
  cal_all.init(_.extend(options, defaultOptions))

  cal_error = new CalHeatMap()
  options =
    itemSelector: '#cal-heatmap-error'
    data: 'records/error-all'
    legend: [1, 5, 10, 15, 20]
    legendColors: ["#ecf5e2", "#c12321"]
    nextSelector: "#error-next",
    previousSelector: "#error-previous"
  cal_error.init(_.extend(options, defaultOptions))

  # [ToDo] use defalutOptions
  cal = []
  $.get 'databases', (databases)->
    - _.each databases, (database) ->
      cal[database] = new CalHeatMap()
      options =
        itemSelector: "#cal-heatmap-#{database}"
        data: "records/#{database}"
        nextSelector: "##{database}-next"
        previousSelector: "##{database}-previous"
      cal[database].init(_.extend(options, defaultOptions))

      cal["error-#{database}"] = new CalHeatMap()
      options =
        itemSelector: "#cal-heatmap-error-#{database}"
        data: "records/error-#{database}"
        legend: [1, 5, 10, 15, 20]
        legendColors: ["#ecf5e2", "#c12321"]
        nextSelector: "##{database}-error-next"
        previousSelector: "##{database}-error-previous"
      cal["error-#{database}"].init(_.extend(options, defaultOptions))

      $.getJSON "./records/count-#{database}", (data) ->
        array_data = _.map _.pairs(data), (d)->
          [Number(d[0]) * 1000, d[1]]
        $("#delta-#{database}").text "#{array_data[array_data.length - 1][1]}(+#{array_data[array_data.length - 1][1] - array_data[array_data.length - 2][1]})"
        $("#count-#{database}").highcharts
          chart:
            width: 500
            height: 100
          xAxis:
            type: 'datetime'
          series:
            [
              data: array_data
            ]

    $.getJSON "./elapsed", (data) ->
      $("#elapsed").highcharts
        chart:
          height: 200
        credits:
          enabled: false
        yAxis:
          min: 0
        series:
          [
            data: _.values(data)
            lineWidth: 1
            marker:
              radius: 0
          ]
