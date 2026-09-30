import uuid
from datetime import timedelta

import pytest
from django.core.files.storage import default_storage
from django.utils import timezone

from accounts.models import User
from social import media
from social.models import Follow, Post, Profile, Report

from .conftest import client_for

pytestmark = pytest.mark.django_db
PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 1000


def person(email, handle, private=False, name=None):
    user = User.objects.create_user(email)
    c = client_for(user)
    r = c.put(
        "/api/social/profile",
        {
            "handle": handle,
            "display_name": name or handle.title(),
            "is_private": private,
        },
        format="json",
    )
    assert r.status_code == 200, r.json()
    return c


def publish(c, audience="public", image=True, **over):
    post_id = str(uuid.uuid4())
    body = {
        "kind": "catch",
        "audience": audience,
        "species_id": "salminus-brasiliensis",
        "caption": "Primeiro do ano",
        "width": 1080,
        "height": 1920,
        "created_at": timezone.now().isoformat(),
        **over,
    }
    r = c.put(f"/api/social/posts/{post_id}", body, format="json")
    assert r.status_code == 200, r.json()
    assert r.json()["needs_image"] is True
    if image:
        r = c.generic(
            "PUT", f"/api/social/posts/{post_id}/image", PNG, content_type="image/png"
        )
        assert r.status_code == 204
    return post_id


def feed_ids(c, scope="following"):
    r = c.get(f"/api/social/feed?scope={scope}")
    assert r.status_code == 200
    return [p["id"] for p in r.json()["results"]]


def follow(c, handle):
    return c.post(f"/api/social/people/{handle}/follow").json()["status"]


class TestProfile:
    def test_no_profile_until_set_up(self, client):
        assert client.get("/api/social/profile").status_code == 404

    def test_handles_are_lowercase_unique_and_not_reserved(self, client):
        r = client.put(
            "/api/social/profile",
            {"handle": "@Ana.Pesca", "display_name": " Ana "},
            format="json",
        )
        assert r.status_code == 200
        assert r.json()["handle"] == "ana.pesca"
        assert r.json()["display_name"] == "Ana"
        # Private by default.
        assert r.json()["is_private"] is True
        bia = client_for(User.objects.create_user("bia@example.com"))
        for handle, error in [
            ("ana.pesca", "handle_taken"),
            ("piscatio", "handle_reserved"),
            ("a", None),
            ("com espaço", None),
        ]:
            r = bia.put(
                "/api/social/profile",
                {"handle": handle, "display_name": "Bia"},
                format="json",
            )
            assert r.status_code == 400
            if error:
                assert r.json()["handle"] == [error]

    def test_avatar_upload_and_link(self, client):
        assert (
            client.generic(
                "PUT", "/api/social/profile/avatar", PNG, content_type="image/png"
            ).status_code
            == 409
        )
        client.put(
            "/api/social/profile",
            {"handle": "ana", "display_name": "Ana"},
            format="json",
        )
        r = client.generic(
            "PUT", "/api/social/profile/avatar", PNG, content_type="image/png"
        )
        url = r.json()["avatar_url"]
        assert "/api/social/media/" in url
        # The link works without signing in.
        image = client_for(User.objects.create_user("x@example.com")).get(url)
        assert b"".join(image.streaming_content) == PNG

    def test_leaving_the_community_keeps_the_logbook(self, client, user):
        client.put(
            "/api/social/profile",
            {"handle": "ana", "display_name": "Ana", "is_private": False},
            format="json",
        )
        post_id = publish(client)
        name = Post.objects.get(pk=post_id).image_name
        assert client.delete("/api/social/profile").status_code == 204
        assert not Profile.objects.exists()
        assert not Post.objects.exists()
        assert not default_storage.exists(name)
        assert User.objects.filter(pk=user.pk).exists()


class TestFollowing:
    def test_public_profiles_are_followed_at_once(self):
        ana = person("ana@x.com", "ana")
        person("bia@x.com", "bia")
        assert follow(ana, "bia") == "accepted"
        r = ana.get("/api/social/people/bia").json()
        assert r["relationship"]["following"] == "accepted"
        assert r["followers"] == 1
        assert ana.delete("/api/social/people/bia/follow").status_code == 200
        assert ana.get("/api/social/people/bia").json()["followers"] == 0

    def test_private_profiles_approve_requests(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia", private=True)
        assert follow(ana, "bia") == "pending"
        assert bia.get("/api/social/profile").json()["requests"] == 1
        waiting = bia.get("/api/social/requests").json()["results"]
        assert [p["handle"] for p in waiting] == ["ana"]
        assert bia.post("/api/social/requests/ana").status_code == 204
        assert (
            ana.get("/api/social/people/bia").json()["relationship"]["following"]
            == "accepted"
        )

    def test_declining_and_going_public(self):
        ana = person("ana@x.com", "ana")
        cid = person("cid@x.com", "cid")
        bia = person("bia@x.com", "bia", private=True)
        follow(ana, "bia")
        follow(cid, "bia")
        bia.delete("/api/social/requests/ana")
        assert not Follow.objects.filter(follower__email="ana@x.com").exists()
        # Going public lets everyone waiting in.
        bia.put(
            "/api/social/profile",
            {"handle": "bia", "display_name": "Bia", "is_private": False},
            format="json",
        )
        assert Follow.objects.get(follower__email="cid@x.com").status == "accepted"

    def test_following_needs_a_profile(self, client):
        person("bia@x.com", "bia")
        r = client.post("/api/social/people/bia/follow")
        assert r.status_code == 409
        assert r.json()["detail"] == "profile_required"

    def test_friends_follow_each_other(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        follow(ana, "bia")
        assert (
            ana.get("/api/social/people/bia").json()["relationship"]["friends"] is False
        )
        follow(bia, "ana")
        rel = ana.get("/api/social/people/bia").json()["relationship"]
        assert rel["friends"] is True and rel["follows_you"] is True

    def test_removing_a_follower(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        follow(ana, "bia")
        assert bia.delete("/api/social/people/ana/follower").status_code == 204
        assert not Follow.objects.exists()

    def test_private_lists_stay_private(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia", private=True)
        cid = person("cid@x.com", "cid")
        follow(cid, "bia")
        bia.post("/api/social/requests/cid")
        assert ana.get("/api/social/people/bia/followers").json()["results"] == []
        assert ana.get("/api/social/people/bia").json()["can_see"] is False
        followers = cid.get("/api/social/people/bia/followers").json()["results"]
        assert [p["handle"] for p in followers] == ["cid"]

    def test_search_by_handle_or_name_without_accents(self):
        ana = person("ana@x.com", "ana")
        person("joao@x.com", "jpesca", name="João Pescador")
        found = ana.get("/api/social/people?q=joao").json()["results"]
        assert [p["handle"] for p in found] == ["jpesca"]
        assert ana.get("/api/social/people?q=j").json()["results"] == []


class TestVisibility:
    def test_public_posts_of_public_profiles_reach_everyone(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia)
        assert post_id in feed_ids(ana, "discover")
        # Following is for people you follow.
        assert post_id not in feed_ids(ana)
        follow(ana, "bia")
        assert post_id in feed_ids(ana)
        assert post_id in feed_ids(bia)

    def test_private_profiles_reach_only_accepted_followers(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia", private=True)
        post_id = publish(bia)
        assert post_id not in feed_ids(ana, "discover")
        follow(ana, "bia")
        assert ana.get("/api/social/people/bia/posts").json()["results"] == []
        assert ana.get(f"/api/social/posts/{post_id}").status_code == 404
        bia.post("/api/social/requests/ana")
        assert post_id in feed_ids(ana)
        assert ana.get(f"/api/social/posts/{post_id}").status_code == 200

    def test_friends_posts_reach_only_friends(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia, audience="friends")
        follow(ana, "bia")
        assert post_id not in feed_ids(ana)
        assert post_id not in feed_ids(ana, "discover")
        follow(bia, "ana")
        assert post_id in feed_ids(ana)
        # Never in discover, even for friends.
        assert post_id not in feed_ids(ana, "discover")

    def test_a_block_hides_everything_both_ways(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia)
        follow(ana, "bia")
        follow(bia, "ana")
        assert bia.post("/api/social/people/ana/block").status_code == 204
        assert not Follow.objects.exists()
        assert post_id not in feed_ids(ana, "discover")
        assert ana.get("/api/social/people/bia").status_code == 404
        assert ana.get("/api/social/people?q=bia").json()["results"] == []
        assert ana.post("/api/social/people/bia/follow").status_code == 404
        assert bia.get("/api/social/people/ana").status_code == 404
        assert [
            p["handle"] for p in bia.get("/api/social/blocks").json()["results"]
        ] == ["ana"]
        bia.delete("/api/social/people/ana/block")
        assert post_id in feed_ids(ana, "discover")

    def test_posts_without_an_image_are_not_published(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia, image=False)
        assert post_id not in feed_ids(ana, "discover")
        assert post_id not in feed_ids(bia)

    def test_hidden_posts_reach_only_their_author(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia)
        Post.objects.filter(pk=post_id).update(hidden_at=timezone.now())
        assert post_id not in feed_ids(ana, "discover")
        assert post_id in feed_ids(bia)

    def test_the_feed_comes_in_pages(self, monkeypatch):
        monkeypatch.setattr("social.views.PAGE", 3)
        ana = person("ana@x.com", "ana")
        start = timezone.now() - timedelta(days=1)
        ids = [
            publish(ana, created_at=(start + timedelta(minutes=i)).isoformat())
            for i in range(7)
        ]
        seen, cursor = [], None
        while True:
            url = "/api/social/feed" + (f"?before={cursor}" if cursor else "")
            page = ana.get(url).json()
            seen += [p["id"] for p in page["results"]]
            cursor = page["next"]
            if cursor is None:
                break
        assert seen == list(reversed(ids))
        assert ana.get("/api/social/feed?before=nope").status_code == 400


class TestPosts:
    def test_publishing_is_idempotent_and_only_yours(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(ana)
        again = ana.put(
            f"/api/social/posts/{post_id}",
            {
                "kind": "catch",
                "audience": "friends",
                "width": 1080,
                "height": 1080,
                "caption": "Editado",
                "created_at": timezone.now().isoformat(),
            },
            format="json",
        )
        assert again.json()["needs_image"] is False
        assert Post.objects.get(pk=post_id).audience == "friends"
        assert Post.objects.count() == 1
        r = bia.put(
            f"/api/social/posts/{post_id}",
            {
                "kind": "catch",
                "audience": "public",
                "width": 1,
                "height": 1,
                "created_at": timezone.now().isoformat(),
            },
            format="json",
        )
        assert r.status_code == 404
        assert (
            bia.generic(
                "PUT",
                f"/api/social/posts/{post_id}/image",
                PNG,
                content_type="image/png",
            ).status_code
            == 404
        )

    def test_publishing_needs_a_profile(self, client):
        r = client.put(
            f"/api/social/posts/{uuid.uuid4()}",
            {
                "kind": "catch",
                "audience": "public",
                "width": 1,
                "height": 1,
                "created_at": timezone.now().isoformat(),
            },
            format="json",
        )
        assert r.status_code == 409

    def test_the_image_link_reaches_others(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia)
        item = ana.get(f"/api/social/posts/{post_id}").json()
        assert item["author"]["handle"] == "bia"
        assert item["mine"] is False
        assert item["caption"] == "Primeiro do ano"
        image = ana.get(item["image_url"])
        assert image.status_code == 200
        assert b"".join(image.streaming_content) == PNG

    def test_only_images_are_accepted(self):
        ana = person("ana@x.com", "ana")
        post_id = publish(ana, image=False)
        r = ana.generic(
            "PUT",
            f"/api/social/posts/{post_id}/image",
            b"hi",
            content_type="text/plain",
        )
        assert r.status_code == 415

    def test_deleting_removes_the_image(self):
        ana = person("ana@x.com", "ana")
        post_id = publish(ana)
        name = Post.objects.get(pk=post_id).image_name
        assert ana.delete(f"/api/social/posts/{post_id}").status_code == 204
        assert not default_storage.exists(name)
        assert post_id not in feed_ids(ana)
        # A late retry of the upload does not bring it back.
        r = ana.put(
            f"/api/social/posts/{post_id}",
            {
                "kind": "catch",
                "audience": "public",
                "width": 1,
                "height": 1,
                "created_at": timezone.now().isoformat(),
            },
            format="json",
        )
        assert r.status_code == 410

    def test_a_missing_venue_is_dropped(self):
        ana = person("ana@x.com", "ana")
        post_id = publish(ana, venue_id=str(uuid.uuid4()))
        assert Post.objects.get(pk=post_id).venue_id is None

    def test_likes_count_once_per_person(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia)
        assert ana.post(f"/api/social/posts/{post_id}/like").json() == {
            "like_count": 1,
            "liked": True,
        }
        assert ana.post(f"/api/social/posts/{post_id}/like").json()["like_count"] == 1
        assert ana.get(f"/api/social/posts/{post_id}").json()["liked"] is True
        assert ana.delete(f"/api/social/posts/{post_id}/like").json() == {
            "like_count": 0,
            "liked": False,
        }

    def test_nothing_unseen_can_be_liked_or_reported(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia, audience="friends")
        assert ana.post(f"/api/social/posts/{post_id}/like").status_code == 404
        r = ana.post(
            "/api/social/reports",
            {"post_id": post_id, "reason": "spam"},
            format="json",
        )
        assert r.status_code == 404

    def test_reports_reach_moderation(self):
        ana = person("ana@x.com", "ana")
        bia = person("bia@x.com", "bia")
        post_id = publish(bia)
        r = ana.post(
            "/api/social/reports",
            {"post_id": post_id, "reason": "location", "note": "Mostra o ponto"},
            format="json",
        )
        assert r.status_code == 201
        assert (
            ana.post(
                "/api/social/reports",
                {"handle": "bia", "reason": "abuse"},
                format="json",
            ).status_code
            == 201
        )
        assert Report.objects.count() == 2
        assert (
            ana.post(
                "/api/social/reports", {"reason": "abuse"}, format="json"
            ).status_code
            == 400
        )


class TestMedia:
    def test_links_are_signed_and_expire(self, monkeypatch):
        ana = person("ana@x.com", "ana")
        post_id = publish(ana)
        url = ana.get(f"/api/social/posts/{post_id}").json()["image_url"]
        token = url.rsplit("/", 1)[1]
        assert ana.get(url.replace(token, token[:-2] + "xx")).status_code == 404
        # The same link all day, so the app can cache the image.
        assert ana.get(f"/api/social/posts/{post_id}").json()["image_url"] == url
        today = media._today()
        monkeypatch.setattr("social.media._today", lambda: today + 1)
        assert ana.get(url).status_code == 200
        monkeypatch.setattr("social.media._today", lambda: today + 2)
        assert ana.get(url).status_code == 404


class TestAccount:
    def test_export_includes_the_community(self):
        ana = person("ana@x.com", "ana")
        person("bia@x.com", "bia")
        follow(ana, "bia")
        publish(ana)
        data = ana.get("/api/account").json()["social"]
        assert data["profile"]["handle"] == "ana"
        assert len(data["posts"]) == 1
        assert data["following"] == ["bia"]
        assert data["followers"] == []

    def test_deleting_the_account_removes_post_images(self):
        ana = person("ana@x.com", "ana")
        post_id = publish(ana)
        name = Post.objects.get(pk=post_id).image_name
        assert ana.delete("/api/account").status_code == 204
        assert not default_storage.exists(name)
        assert not Post.objects.exists()
