---
layout: page
title: Concepts
permalink: /concepts/
nav_order: 2
---

# Concepts
{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

## Home/Browse View

The idea behind the two views is to have one main view, your **Home View**, acting as quick access to your most often needed images, like for example your camera pictures, and a second view which is your workhorse providing access to all other images you have on your cloud, your **Browse View**.

Every view has its view specific settings which can be found in the drop down menu in the top right. This settings only affect the current view.

## Search

The search function acts currently more like a local filter then a real search. It will filter your local view based on name or based on the last modified date. The date formating is the same as the one displayed by the category view, for example 2020-06-08. Furthermore you are not required to enter a full date. Entering only 2020 will return everthing from 2020, while entering 2020-06 will return everything from June 2020.

Searching Browse View allows also for filtering the folder list and to continue navigation directly from the search results.

{: .d-lg-flex .flex-justify-between}
<img src="{{site.data.yaga.asset_url}}/assets/videos/search_home_view.gif" alt="Search Home View" width="250"/>
<img class="ml-lg-2" src="{{site.data.yaga.asset_url}}/assets/videos/search_browse_view.gif" alt="Search Browse View" width="250"/>

## Image State

The small token in the right lower corner of each image shows you the storage state of that image. 
* A **cloud** means the images exists on the server.
* A green **check** means the image exists on the server and is downloaded.
* A **phone** symbol means the image exists only locally on your phone.

<img src="{{site.data.yaga.asset_url}}/assets/images/cloud.png" alt="Cloud" width="100"/>
<img class="ml-2" src="{{site.data.yaga.asset_url}}/assets/images/check.png" alt="Check" width="100"/>
<img class="ml-2" src="{{site.data.yaga.asset_url}}/assets/images/phone.png" alt="Phone" width="100"/>

## Focus Mode

Focus mode exists only in the Browse View and alows you to open the current folder in a Home View like view without having to change the path setting of your Home View. This is especially usefull if you want to have a look on recursive files from the current folder.