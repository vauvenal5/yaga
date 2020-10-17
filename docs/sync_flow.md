---
layout: page
title: Sync Flow
permalink: /sync_flow/
nav_order: 4
---

# Sync Flow

Nextcloud Yaga itself does not yet support any upload or sync functionality. You need to relay on the Nextcloud app for that. However, thanks to Nextclouds sync abilities it is easy and recommended to setup a dual app workflow.

In this workflow the Nextcloud app will take over the process of syncing images to your server. For this to work you will have to set up auto-upload in your Nextcloud app for the respective directories. It does not matter if you keep the images in the original folder or if you move them to the Nextcloud folder, although the latter has some advantages as we will see.

Now that the uploading part is all set you have to set up the Nextcloud Yaga app to be able to find those auto-synced images on your device. For this you have to set the **Root Mapping** in your global settings correctly.

<div class="d-lg-flex flex-justify-between align-flex-start">
    <div class="content">
        In case you configured your auto-upload(s) to move images to the Nextcloud app folder, then you can specify for the <b>Remote Path</b> simply your Nextcloud's server root directory and for your <b>Local Path</b> you can set the Nextcloud app folder. This will result in a setup where your Nextcloud app folder will always represent your servers structure and Nextcloud Yaga will put downloaded images into that structure. This brings a few advantages:
        <ul>
            <li>Your Nextcloud app also knows about the downloaded images</li>
            <li>You are saving storage since the Nextcloud Yaga app does only download images which are not already on your phone.</li>
            <li>You can easily cover multiple auto-uploads with this strategy.</li>
        </ul>
        In case you configured your auto-upload to keep images where they are, then you can specifiy for the <b>Remote Path</b> the same server directory as for the auto-upload and for the <b>Local Path</b> you can set the local folder where you keep your images. This way Nextcloud Yaga will know not to re-download those images. Other images you download will be saved to Nextcloud Yaga's app folder.
        <ul>
            <li>This works only with one auto-upload</li>
        </ul>
    </div>
    <img class="ml-lg-2" src="{{site.data.yaga.asset_url}}/assets/videos/root_mapping.gif" alt="Root Mapping" width="250"/>
</div>