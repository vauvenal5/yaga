---
layout: page
title: Settings Overview
permalink: /settings/
nav_order: 3
---

# Settings Overview
{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

Nextcloud Yaga has two types of settings, global and view local. **Global settings** have influence on **the entire app** and can be found in the app drawer. **View local settings** on the other hand are local to the **current view** and can be found in the respective drop down menu.

## Global Settings

### Root Mapping
The root mapping allows you to specify a storage directory for downloaded images. More specifically you can specify one local path for one remote path. If you set the remote path to your Nextcloud root then all images downloaded to your local path will reassemble your remote file structure. If you set your remote path to a sub path then all images from this sub path will be saved to the specified local path. Images outside of this remote path will be saved to the Nextcloud Yaga default storage directory.

See also: How to set up an advanced image <a href="{{site.baseurl}}/sync_flow/">sync flow</a> with the Nextcloud app and Nextcloud Yaga.

### Theme
The theme setting allows you to switch the color theme of the app between **light**, **dark**, and **follow system theme**.

## View Local Settings

Note that the **Home View** and the **Browse View** do not necessarily have the same settings.

### Path
This path settings specifies which folder to display in your home view. See also the [Quickstart guide]({{site.baseurl}}/quickstart/) for a demonstration.

### Load Recursively
Tells Yaga to load also images from sub-directories of the selected [Path]({{site.baseurl}}/settings/#path).

### View Type
Allows you to change how images are displayed in your view.

#### Category View (default)

<div class="d-lg-flex flex-justify-between align-flex-start">
    <div class="content">
        <p>Category view with date modified being the category. Sorted by newest category first. This is the default view. <b>Home View</b> only.</p>
        Please note, that there are currently two different version of <b>Category View</b> for performance evaluation reasons. Currently we recommend using the <b>experimental</b> view in case you use a catefory view.
    </div>
    <img class="ml-lg-2" src="{{site.data.yaga.asset_url}}/assets/screenshots/all_set.png" alt="Category View" width="250"/>
</div>

#### Grid View

<div class="d-lg-flex flex-justify-between align-flex-start">
    <div class="content">
        Simple grid view sorted by newest first.
    </div>
    <img class="ml-lg-2" src="{{site.data.yaga.asset_url}}/assets/screenshots/grid_view.png" alt="Category View" width="250"/>
</div>

#### List View

<div class="d-lg-flex flex-justify-between align-flex-start">
    <div class="content">
        Simple list view sorted alphabetically.
    </div>
    <img class="ml-lg-2" src="{{site.data.yaga.asset_url}}/assets/screenshots/list_view.png" alt="Category View" width="250"/>
</div>