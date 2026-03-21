package com.aiwisdombattle.client;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdaptiveEngineClientTest {

    private RestTemplate restTemplate;
    private AdaptiveEngineClient client;

    @BeforeEach
    void setUp() {
        restTemplate = mock(RestTemplate.class);
        client = new AdaptiveEngineClient(restTemplate);
    }

    @Test
    void computeAdaptiveScore_returnsAdaptiveScore_whenEngineResponds() {
        var response = new AdaptiveEngineClient.ScoreResponse(92.5, 1.2, 1.1, 0.0, 0.05, 0.03);
        when(restTemplate.postForObject(eq("/scoring"), any(), eq(AdaptiveEngineClient.ScoreResponse.class)))
            .thenReturn(response);

        double result = client.computeAdaptiveScore(80, 250, 3);

        assertThat(result).isEqualTo(92.5);
    }

    @Test
    void computeAdaptiveScore_fallsBackToRawScore_whenEngineThrows() {
        when(restTemplate.postForObject(eq("/scoring"), any(), eq(AdaptiveEngineClient.ScoreResponse.class)))
            .thenThrow(new RestClientException("Connection refused"));

        double result = client.computeAdaptiveScore(75, 300, 2);

        assertThat(result).isEqualTo(75.0);
    }

    @Test
    void computeAdaptiveScore_fallsBackToRawScore_whenResponseIsNull() {
        when(restTemplate.postForObject(eq("/scoring"), any(), eq(AdaptiveEngineClient.ScoreResponse.class)))
            .thenReturn(null);

        double result = client.computeAdaptiveScore(60, 400, 4);

        assertThat(result).isEqualTo(60.0);
    }
}
