package sm2_test

import (
	"testing"

	"github.com/aiwisdombattle/backend/pkg/sm2"
)

func TestCalculate_FailedQuality(t *testing.T) {
	// quality < 3 should reset
	for q := 0; q <= 2; q++ {
		r := sm2.Calculate(q, 3, 2.5, 10)
		if !r.IsReset {
			t.Errorf("quality=%d: expected IsReset=true, got false", q)
		}
		if r.NewRepetitions != 0 {
			t.Errorf("quality=%d: expected NewRepetitions=0, got %d", q, r.NewRepetitions)
		}
		if r.NextInterval != 1 {
			t.Errorf("quality=%d: expected NextInterval=1, got %d", q, r.NextInterval)
		}
	}
}

func TestCalculate_FirstRepetition(t *testing.T) {
	r := sm2.Calculate(5, 0, 2.5, 0)
	if r.NextInterval != 1 {
		t.Errorf("first repetition: expected NextInterval=1, got %d", r.NextInterval)
	}
	if r.NewRepetitions != 1 {
		t.Errorf("first repetition: expected NewRepetitions=1, got %d", r.NewRepetitions)
	}
}

func TestCalculate_SecondRepetition(t *testing.T) {
	r := sm2.Calculate(5, 1, 2.5, 1)
	if r.NextInterval != 6 {
		t.Errorf("second repetition: expected NextInterval=6, got %d", r.NextInterval)
	}
}

func TestCalculate_ThirdRepetitionUp(t *testing.T) {
	r := sm2.Calculate(5, 2, 2.5, 6)
	// interval = round(6 * 2.6) = 16
	if r.NextInterval <= 6 {
		t.Errorf("third repetition: expected NextInterval > 6, got %d", r.NextInterval)
	}
}

func TestCalculate_EasinessFloor(t *testing.T) {
	// Quality 3 should not drop easiness below 1.3
	r := sm2.Calculate(3, 5, 1.3, 10)
	if r.NewEasiness < 1.3 {
		t.Errorf("easiness floor violated: got %f", r.NewEasiness)
	}
}

func TestQualityFromScore(t *testing.T) {
	cases := []struct{ score, want int }{
		{0, 0}, {19, 0}, {20, 1}, {60, 3}, {100, 5}, {110, 5},
	}
	for _, c := range cases {
		got := sm2.QualityFromScore(c.score)
		if got != c.want {
			t.Errorf("QualityFromScore(%d) = %d, want %d", c.score, got, c.want)
		}
	}
}

func TestAdaptiveScore(t *testing.T) {
	// difficulty bonus: (difficulty-1)*2
	score := sm2.AdaptiveScore(90, 300, 3) // 90 + (3-1)*2 = 94
	if score != 94 {
		t.Errorf("AdaptiveScore = %f, want 94", score)
	}
	// capped at 100
	capped := sm2.AdaptiveScore(100, 300, 5) // 100 + 8 → capped at 100
	if capped != 100 {
		t.Errorf("AdaptiveScore capped = %f, want 100", capped)
	}
}
