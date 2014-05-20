# -*- coding: utf-8 -*-
# 2012/12/28
# カラーピッカー
require 'gtk2'
include Gtk

require 'scanf'

require "./rgb_db.rb"

class MainWindow < Window
  def initialize
    @db = RGB_DB.new

    super
    self.signal_connect("delete-event") {
      Gtk.main_quit
    }
    self.title = "カラーピッカー"

    @vbox = VBox.new(false, 10)
    self.add(@vbox)

    @color_selection = ColorSelection.new
    @color_selection.no_show_all = true
    @color_selection.has_opacity_control = false
    @vbox.pack_start(@color_selection, false, false)
    @color_selection.signal_connect("color-changed") { 
      color = @color_selection.current_color
      str = ColorSelection.palette_to_string(color)
      name = @db.from_code_to_names(str)
      if not name.empty?
        @xname_label.text = name.join(", ")
      else
        @xname_label.text = "(名前がみつからないよ)"
      end

      similar_names = @db.find_similar_named_color(str)
      if not similar_names.empty?
        @sname_label.text = similar_names.join(", ")
      else
        @sname_label.text = "(似た色名はみつからないよ)"
      end
    }

    @xname_label = Label.new("(色名)")
    @vbox.pack_start(@xname_label, false, false)

    @sname_label = Label.new("(類似の色名)")
    @sname_label.wrap = true
    @sname_label.set_height_request(12 * 3)
    @vbox.pack_start(@sname_label, false, false)

    @entry_hbox = HBox.new
    @entry_label = Label.new("名前で検索: ")
    @entry_hbox.pack_start(@entry_label, false, false)
    @xname_entry = Entry.new
    @xname_entry.no_show_all = true
    @xname_entry.signal_connect("activate") {
      # 入力された色名に該当する色がある場合は、
      # それを表示する
      str = @xname_entry.text
      next if str == ""
      code = @db.from_name_to_code(str)
      next unless code
      gdk_color = ColorSelection.palette_from_string(code)[0]
      @color_selection.current_color = gdk_color
    }
    @entry_hbox.pack_start(@xname_entry, true, true)
    @vbox.pack_start(@entry_hbox, false, false)

    @model = ListStore.new(String, String)
    @treeview = TreeView.new(@model)
    cr = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new("名前", cr, :text=>0)
    cr2 = Gtk::CellRendererText.new
    col2 = Gtk::TreeViewColumn.new("コード", cr2, :text=>1)

    col2.set_cell_data_func(cr2) do |col, renderer, model, iter|
      code = iter[1]
      renderer.background = code
      r, g, b = code.scanf("#%2X%2X%2X")
      # ある程度暗ければ白い文字にする
      if (r*0.8+g*2+b*0.2)/3 < 128
        renderer.foreground = "white"
      else
        renderer.foreground = "black"
      end
    end

    @treeview.headers_visible = true
    @treeview.append_column(col)
    @treeview.append_column(col2)

    @xname_entry.signal_connect("activate") {
      # 入力された文字列を部分文字列とする色名
      # をリスト表示する
      str = @xname_entry.text
      @model.clear
      @db.name2code.each_pair do |key, value|
        if key =~ /#{str}/i
          iter = @model.append
          iter[0] = key; iter[1] = value
        end
      end
    }

    @treeview.signal_connect("cursor-changed") { |t|
      path, column = t.cursor
      iter = @model.get_iter(path)
      code = @db.from_name_to_code(iter[0])
      gdk_color = ColorSelection.palette_from_string(code)[0]
      @color_selection.current_color = gdk_color
    }


    @scrolled_window = ScrolledWindow.new
    @scrolled_window.height_request = 150
    @scrolled_window.add @treeview
    @scrolled_window.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)

    @vbox.pack_start(@scrolled_window, true, true)

    self.border_width = 20
#    self.set_default_size(640, 640)
  end

  def show_text_widgets
    @xname_entry.show
    @color_selection.show_all
    @color_selection.show
  end

end

$main_window = MainWindow.new.show_all
$main_window.show_text_widgets

Gtk.main
