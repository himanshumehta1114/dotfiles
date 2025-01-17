local awful = require "awful"
local beautiful = require "beautiful"
local gears = require "gears"
local naughty = require "naughty"
local wibox = require "wibox"

local notifs_text = wibox.widget {
  font = beautiful.font_name .. " Bold 8",
  markup = "Notifications",
  valign = "center",
  widget = wibox.widget.textbox,
}

local notifs_clear = wibox.widget {
  markup = "<span foreground='" .. beautiful.fg_dark .. "'>x</span>",
  font = beautiful.font_name .. " Bold 9",
  align = "center",
  valign = "center",
  widget = wibox.widget.textbox,
}

notifs_clear:buttons(gears.table.join(awful.button({}, 1, function()
  _G.reset_notifs_container()
end)))

local notifs_empty = wibox.widget {
  {
    nil,
    {
      nil,
      {
        markup = "<span foreground='" .. beautiful.fg_dark .. "'>No Notifications</span>",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
      },
      expand = "none",
      layout = wibox.layout.align.vertical,
    },
    expand = "none",
    layout = wibox.layout.align.horizontal,
  },
  forced_height = 110,
  widget = wibox.container.background,
}

local notifs_container = wibox.widget {
  spacing = 6,
  spacing_widget = {
    {
      shape = gears.shape.rounded_rect,
      widget = wibox.container.background,
    },
    top = 2,
    bottom = 2,
    left = 53,
    right = 6,
    widget = wibox.container.margin,
  },
  forced_width = beautiful.notifs_width or 240,
  layout = wibox.layout.fixed.vertical,
}

local remove_notifs_empty = true

reset_notifs_container = function()
  notifs_container:reset(notifs_container)
  notifs_container:insert(1, notifs_empty)
  remove_notifs_empty = true
end

remove_notif = function(box)
  notifs_container:remove_widgets(box)

  if #notifs_container.children == 0 then
    notifs_container:insert(1, notifs_empty)
    remove_notifs_empty = true
  end
end

local create_notif = function(icon, n, width)
  local time = os.date "%H:%M"
  local box = {}

  box = wibox.widget {
    {
      {
        {
          {
            image = icon,
            resize = true,
            -- clip_shape = helpers.rrect(dpi(2)),
            halign = "center",
            valign = "center",
            widget = wibox.widget.imagebox,
          },
          strategy = "exact",
          height = 40,
          width = 40,
          widget = wibox.container.constraint,
        },
        {
          {
            nil,
            {
              {
                {
                  step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
                  speed = 50,
                  {
                    markup = n.title,
                    font = beautiful.font_name .. " Medium 8",
                    align = "left",
                    widget = wibox.widget.textbox,
                  },
                  forced_width = 140,
                  widget = wibox.container.scroll.horizontal,
                },
                nil,
                {
                  markup = "<span foreground='" .. beautiful.fg_dark .. "'>" .. time .. "</span>",
                  align = "right",
                  valign = "bottom",
                  font = beautiful.font,
                  widget = wibox.widget.textbox,
                },
                expand = "none",
                layout = wibox.layout.align.horizontal,
              },
              {
                markup = n.message,
                align = "left",
                forced_width = 165,
                widget = wibox.widget.textbox,
              },
              spacing = 2,
              layout = wibox.layout.fixed.vertical,
            },
            expand = "none",
            layout = wibox.layout.align.vertical,
          },
          left = 12,
          widget = wibox.container.margin,
        },
        layout = wibox.layout.align.horizontal,
      },
      margins = 6,
      widget = wibox.container.margin,
    },
    forced_height = 50,
    widget = wibox.container.background,
  }

  box:buttons(gears.table.join(awful.button({}, 1, function()
    _G.remove_notif(box)
  end)))

  return box
end

notifs_container:buttons(gears.table.join(
  awful.button({}, 4, nil, function()
    if #notifs_container.children == 1 then
      return
    end
    notifs_container:insert(1, notifs_container.children[#notifs_container.children])
    notifs_container:remove(#notifs_container.children)
  end),

  awful.button({}, 5, nil, function()
    if #notifs_container.children == 1 then
      return
    end
    notifs_container:insert(#notifs_container.children + 1, notifs_container.children[1])
    notifs_container:remove(1)
  end)
))

notifs_container:insert(1, notifs_empty)

naughty.connect_signal("request::display", function(n)
  if #notifs_container.children == 1 and remove_notifs_empty then
    notifs_container:reset(notifs_container)
    remove_notifs_empty = false
  end

  local notif_color = beautiful.groups_bg
  local appicon = n.icon or n.app_icon
  if not appicon then
    appicon = beautiful.notification_icon
  end

  notifs_container:insert(1, create_notif(appicon, n, width))
end)

local notifs = wibox.widget {
  {
    {
      notifs_text,
      nil,
      notifs_clear,
      expand = "none",
      layout = wibox.layout.align.horizontal,
    },
    left = 5,
    right = 5,
    layout = wibox.container.margin,
  },
  notifs_container,
  spacing = 10,
  layout = wibox.layout.fixed.vertical,
}

return notifs
